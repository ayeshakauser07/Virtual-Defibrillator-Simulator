function build_defib_simulink_disarm
% BUILD_DEFIB_SIMULINK_DISARM
% Interactive virtual defibrillator with a DISARM button.
% Requires MATLAB and base Simulink. No Simscape is required.
%
% Workflow (like a real device):
%   1. Pick the energy and patient impedance.
%   2. CHARGE : charges the capacitor. A green lamp shows READY.
%   3. Then choose one:
%        SHOCK  : delivers the shock to the patient load.
%        DISARM : safely dumps the stored energy inside the device.
%                 Nothing is delivered to the patient.
%   RESET : returns to 200 J, 50 ohms and clears the display.
%
% Changing the energy while READY disarms the device automatically.
% This is a teaching simulation, not a clinical defibrillator model.

    modelName = 'defib_sim_disarm';

    % Fixed model parameters
    C = 32e-6;       % F
    L = 50e-3;       % H
    Vs = 5000;       % V
    Rc = 30e3;       % ohm
    Rint = 10;       % ohm
    Rdump = 1000;    % ohm, internal dump resistor used by DISARM
    postShockTime = 0.060;  % s

    energyOptions = [50 100 150 200 300 360];
    defaultEnergy = 200;
    defaultRp = 50;

    % Device state
    armed = false;       % true when the capacitor is charged (READY)
    armedData = [];      % saved charge information

    % Build the Simulink model once
    if bdIsLoaded(modelName)
        close_system(modelName, 0);
    end
    if exist([modelName '.slx'], 'file')
        delete([modelName '.slx']);
    end
    createDefibModel(modelName, defaultEnergy, defaultRp, C, L, Vs, Rc, Rint);

    % ----------------------- User interface ----------------------------
    fig = uifigure('Name','Virtual Defibrillator Simulator', ...
        'Position',[80 60 1180 790], 'Color',[0.97 0.98 1.00]);

    uilabel(fig, 'Text','VIRTUAL DEFIBRILLATOR: CHARGE, SHOCK & DISARM', ...
        'Position',[25 748 1130 28], 'FontSize',19, 'FontWeight','bold', ...
        'FontColor',[0.10 0.20 0.36]);

    uilabel(fig,'Text','Selected energy (J)', ...
        'Position',[30 700 150 22],'FontWeight','bold');
    energyDrop = uidropdown(fig,'Items',string(energyOptions), ...
        'ItemsData',energyOptions,'Value',defaultEnergy, ...
        'Position',[30 670 150 30], ...
        'ValueChangedFcn',@onEnergyChanged);

    uilabel(fig,'Text','Patient impedance Rp (ohms)', ...
        'Position',[220 700 240 22],'FontWeight','bold');
    rpSlider = uislider(fig,'Limits',[25 150],'Value',defaultRp, ...
        'MajorTicks',[25 50 75 100 125 150], ...
        'Position',[230 680 300 3]);
    rpValue = uilabel(fig,'Text',sprintf('%.0f ohms',defaultRp), ...
        'Position',[545 667 80 25],'FontWeight','bold');
    rpSlider.ValueChangingFcn = @(src,event) setRpLabel(event.Value);
    rpSlider.ValueChangedFcn  = @(src,event) setRpLabel(src.Value);

    chargeButton = uibutton(fig,'push','Text','CHARGE', ...
        'Position',[640 665 110 42], 'FontSize',14, 'FontWeight','bold', ...
        'BackgroundColor',[0.12 0.48 0.30], 'FontColor',[1 1 1], ...
        'ButtonPushedFcn',@chargeDevice);
    shockButton = uibutton(fig,'push','Text','SHOCK', ...
        'Position',[760 665 110 42], 'FontSize',14, 'FontWeight','bold', ...
        'BackgroundColor',[0.78 0.12 0.12], 'FontColor',[1 1 1], ...
        'ButtonPushedFcn',@deliverShock);
    disarmButton = uibutton(fig,'push','Text','DISARM', ...
        'Position',[880 665 110 42], 'FontSize',14, 'FontWeight','bold', ...
        'BackgroundColor',[0.90 0.55 0.05], 'FontColor',[1 1 1], ...
        'ButtonPushedFcn',@disarmDevice);
    resetButton = uibutton(fig,'push','Text','RESET', ...
        'Position',[1000 665 110 42], 'FontSize',14, 'FontWeight','bold', ...
        'BackgroundColor',[0.35 0.40 0.48], 'FontColor',[1 1 1], ...
        'ButtonPushedFcn',@resetDisplay);

    readyLamp = uilamp(fig,'Position',[30 627 20 20],'Color',[0.6 0.6 0.6]);
    statusLabel = uilabel(fig,'Text','Choose settings, then press CHARGE.', ...
        'Position',[60 625 1050 24], 'FontColor',[0.20 0.25 0.32]);

    % Three axes
    axVc = uiaxes(fig,'Position',[45 405 520 195]);
    initAxes(axVc,'Capacitor voltage','Time (s)','Voltage (V)');
    axI = uiaxes(fig,'Position',[615 405 520 195]);
    initAxes(axI,'Discharge current','Time (s)','Current (A)');
    axE = uiaxes(fig,'Position',[45 145 1090 205]);
    initAxes(axE,'Energy delivered to patient-load resistance','Time (s)','Energy (J)');

    % Result panel
    resultPanel = uipanel(fig,'Title','Automatically calculated results', ...
        'Position',[30 20 1100 105], 'FontWeight','bold');
    metricNames = {'Target voltage','Charge time','Peak current', ...
                   'Delivered energy','Efficiency','Damping'};
    metricValues = gobjects(1,6);
    xPositions = [15 195 375 555 735 915];
    for q = 1:6
        uilabel(resultPanel,'Text',metricNames{q}, ...
            'Position',[xPositions(q) 48 165 20], ...
            'FontWeight','bold','FontSize',11);
        metricValues(q) = uilabel(resultPanel,'Text','-', ...
            'Position',[xPositions(q) 20 165 25], ...
            'FontSize',13,'FontColor',[0.08 0.28 0.48]);
    end

    setButtons('idle');
    open_system(modelName);

    % ------------------------- Helpers ---------------------------------
    function initAxes(ax,ttl,xl,yl)
        title(ax,ttl); xlabel(ax,xl); ylabel(ax,yl); grid(ax,'on');
    end

    function setRpLabel(value)
        rpValue.Text = sprintf('%.0f ohms',value);
    end

    function setButtons(state)
        switch state
            case 'idle'
                chargeButton.Enable = 'on';
                shockButton.Enable  = 'off';
                disarmButton.Enable = 'off';
                readyLamp.Color = [0.6 0.6 0.6];
            case 'ready'
                chargeButton.Enable = 'off';
                shockButton.Enable  = 'on';
                disarmButton.Enable = 'on';
                readyLamp.Color = [0.10 0.80 0.20];
            case 'busy'
                chargeButton.Enable = 'off';
                shockButton.Enable  = 'off';
                disarmButton.Enable = 'off';
                readyLamp.Color = [0.95 0.75 0.10];
        end
        drawnow;
    end

    function clearAllAxes()
        cla(axVc); cla(axI); cla(axE);
        initAxes(axVc,'Capacitor voltage','Time (s)','Voltage (V)');
        initAxes(axI,'Discharge current','Time (s)','Current (A)');
        initAxes(axE,'Energy delivered to patient-load resistance','Time (s)','Energy (J)');
    end

    function clearMetrics()
        for n = 1:numel(metricValues)
            metricValues(n).Text = '-';
        end
    end

    % ------------------------- CHARGE ----------------------------------
    function chargeDevice(~,~)
        Esel = energyDrop.Value;
        Rp = rpSlider.Value;

        Vtarget = sqrt(2*Esel/C);
        if Vtarget >= Vs
            uialert(fig,'Selected energy is too high for the model supply.', ...
                'Invalid energy');
            return;
        end
        tShock = -(Rc*C)*log(1 - Vtarget/Vs);

        setButtons('busy');
        statusLabel.Text = sprintf('Charging to %.0f J ...', Esel);
        drawnow;

        try
            % Run the model only up to the moment charging is complete
            set_param([modelName '/ShockSwitch'],'Time',num2str(tShock,16));
            set_param([modelName '/GainR'],'Gain',num2str(Rp+Rint,16));
            set_param([modelName '/GainRp'],'Gain',num2str(Rp,16));
            set_param(modelName,'StopTime',num2str(tShock,16));
            save_system(modelName);

            simOut = sim(modelName,'ReturnWorkspaceOutputs','on');
            vc = simOut.get('vc_log');
            tVc = vc.Time(:);
            yVc = squeeze(vc.Data); yVc = yVc(:);

            clearAllAxes();
            plot(axVc,tVc,yVc,'LineWidth',1.6);
            hold(axVc,'on');
            plot(axVc,tShock,yVc(end),'go','MarkerFaceColor','g');
            hold(axVc,'off');
            title(axVc,'Capacitor voltage (charged, READY)');

            armedData = struct('E',Esel,'V',Vtarget,'tShock',tShock, ...
                               't',tVc,'v',yVc);
            armed = true;

            clearMetrics();
            metricValues(1).Text = sprintf('%.1f V',Vtarget);
            metricValues(2).Text = sprintf('%.3f s',tShock);

            statusLabel.Text = sprintf(['READY: capacitor charged to %.0f V (%.0f J). ' ...
                'Press SHOCK to deliver or DISARM to dump the energy.'], ...
                yVc(end),Esel);
            setButtons('ready');
        catch ME
            armed = false; armedData = [];
            statusLabel.Text = 'Charging failed. See the error message.';
            setButtons('idle');
            uialert(fig,ME.message,'Simulink simulation error');
        end
    end

    % ------------------------- SHOCK -----------------------------------
    function deliverShock(~,~)
        if ~armed
            uialert(fig,'The device is not charged. Press CHARGE first.', ...
                'Not ready');
            return;
        end
        Esel = armedData.E;
        Rp = rpSlider.Value;
        Vtarget = armedData.V;
        tShock = armedData.tShock;
        tStop = tShock + postShockTime;
        Rtotal = Rp + Rint;

        setButtons('busy');
        statusLabel.Text = 'Delivering shock ...';
        drawnow;

        try
            set_param([modelName '/ShockSwitch'],'Time',num2str(tShock,16));
            set_param([modelName '/GainR'],'Gain',num2str(Rtotal,16));
            set_param([modelName '/GainRp'],'Gain',num2str(Rp,16));
            set_param(modelName,'StopTime',num2str(tStop,16));
            save_system(modelName);

            simOut = sim(modelName,'ReturnWorkspaceOutputs','on');
            vc = simOut.get('vc_log');
            ic = simOut.get('i_log');
            ep = simOut.get('E_log');

            tVc = vc.Time(:); yVc = squeeze(vc.Data); yVc = yVc(:);
            tI  = ic.Time(:); yI  = squeeze(ic.Data); yI  = yI(:);
            tE  = ep.Time(:); yE  = squeeze(ep.Data); yE  = yE(:);

            delivered = yE(end);
            peakCurrent = max(abs(yI));
            voltageAtShock = interp1(tVc,yVc,tShock,'linear','extrap');

            alpha = Rtotal/(2*L);
            omega0 = 1/sqrt(L*C);
            if abs(alpha-omega0) < 1e-8
                damping = 'Critical';
            elseif alpha < omega0
                damping = 'Underdamped';
            else
                damping = 'Overdamped';
            end
            efficiency = 100*delivered/Esel;

            clearAllAxes();
            plot(axVc,tVc,yVc,'LineWidth',1.6);
            hold(axVc,'on'); xline(axVc,tShock,'--r','SHOCK'); hold(axVc,'off');
            title(axVc,'Capacitor voltage');

            plot(axI,tI,yI,'LineWidth',1.6);
            xline(axI,tShock,'--r','SHOCK');
            xlim(axI,[max(0,tShock-0.005) tStop]);
            title(axI,'Discharge current');

            plot(axE,tE,yE,'LineWidth',1.6);
            xline(axE,tShock,'--r','SHOCK');
            xlim(axE,[max(0,tShock-0.005) tStop]);
            title(axE,'Energy delivered to patient-load resistance');

            metricValues(1).Text = sprintf('%.1f V',Vtarget);
            metricValues(2).Text = sprintf('%.3f s',tShock);
            metricValues(3).Text = sprintf('%.2f A',peakCurrent);
            metricValues(4).Text = sprintf('%.2f J',delivered);
            metricValues(5).Text = sprintf('%.2f %%',efficiency);
            metricValues(6).Text = damping;

            statusLabel.Text = sprintf(['SHOCK DELIVERED: E = %.0f J, Rp = %.1f ohms, ' ...
                'voltage at shock = %.1f V. Press CHARGE for another shock.'], ...
                Esel,Rp,voltageAtShock);
            armed = false; armedData = [];
            setButtons('idle');
        catch ME
            statusLabel.Text = 'Shock simulation failed. See the error message.';
            armed = false; armedData = [];
            setButtons('idle');
            uialert(fig,ME.message,'Simulink simulation error');
        end
    end

    % ------------------------- DISARM ----------------------------------
    function disarmDevice(~,~)
        doDisarm('DISARMED: stored energy dumped inside the device. 0 J delivered to the patient.');
    end

    function doDisarm(message)
        if ~armed
            return;
        end
        setButtons('busy');
        V0 = armedData.V;
        tS = armedData.tShock;

        % Internal dump: capacitor discharges through Rdump, not the patient
        td = linspace(0,0.2,400)';
        vd = V0*exp(-td/(Rdump*C));
        idump = vd/Rdump;
        Edump = 0.5*C*vd.^2;

        clearAllAxes();
        plot(axVc,armedData.t,armedData.v,'LineWidth',1.6);
        hold(axVc,'on');
        plot(axVc,tS+td,vd,'r','LineWidth',1.6);
        xline(axVc,tS,'--','DISARM','Color',[0.90 0.55 0.05]);
        hold(axVc,'off');
        title(axVc,'Capacitor voltage (charged, then disarmed)');

        plot(axI,tS+td,idump,'Color',[0.90 0.55 0.05],'LineWidth',1.6);
        title(axI,'Internal dump current (none flows through the patient)');

        plot(axE,tS+td,Edump,'Color',[0.90 0.55 0.05],'LineWidth',1.6);
        title(axE,'Stored energy dumped into the internal resistor');

        metricValues(1).Text = sprintf('%.1f V',V0);
        metricValues(2).Text = sprintf('%.3f s',tS);
        metricValues(3).Text = '0.00 A (patient)';
        metricValues(4).Text = '0.00 J';
        metricValues(5).Text = '-';
        metricValues(6).Text = 'Not applicable';

        statusLabel.Text = message;
        armed = false; armedData = [];
        setButtons('idle');
    end

    function onEnergyChanged(~,~)
        if armed
            doDisarm(['Energy changed while charged: device DISARMED automatically. ' ...
                      'Press CHARGE to charge to the new energy.']);
        end
    end

    % ------------------------- RESET -----------------------------------
    function resetDisplay(~,~)
        armed = false; armedData = [];
        energyDrop.Value = defaultEnergy;
        rpSlider.Value = defaultRp;
        rpValue.Text = sprintf('%.0f ohms',defaultRp);
        clearAllAxes();
        clearMetrics();
        setButtons('idle');
        statusLabel.Text = 'Reset complete. Default settings: 200 J and 50 ohms. Press CHARGE.';
    end
end

function createDefibModel(m,Esel,Rp,C,L,Vs,Rc,Rint)
% Two-phase differential-equation model built from base Simulink blocks.
    Vtarget = sqrt(2*Esel/C);
    tau = Rc*C;
    tShock = -tau*log(1 - Vtarget/Vs);
    tStop = tShock + 0.060;
    Rtotal = Rp + Rint;

    new_system(m);
    open_system(m);
    lib = 'simulink/';
    g = @(x) num2str(x,16);

    add_block([lib 'Sources/Step'],[m '/ShockSwitch'], ...
        'Time',g(tShock),'Before','1','After','0','Position',[30 40 80 70]);
    add_block([lib 'Sources/Constant'],[m '/Vs'], ...
        'Value',g(Vs),'Position',[30 130 80 160]);
    add_block([lib 'Sources/Constant'],[m '/One'], ...
        'Value','1','Position',[30 220 80 250]);

    add_block([lib 'Math Operations/Sum'],[m '/SumNS'], ...
        'Inputs','+-','Position',[130 215 160 255]);
    add_block([lib 'Math Operations/Sum'],[m '/SumV'], ...
        'Inputs','+-','Position',[130 125 160 165]);
    add_block([lib 'Math Operations/Gain'],[m '/GainCharge'], ...
        'Gain',g(1/(Rc*C)),'Position',[200 130 270 160]);
    add_block([lib 'Math Operations/Product'],[m '/ProdCharge'], ...
        'Position',[310 100 340 160]);
    add_block([lib 'Math Operations/Product'],[m '/ProdDis'], ...
        'Position',[310 260 340 320]);
    add_block([lib 'Math Operations/Gain'],[m '/GainC'], ...
        'Gain',g(1/C),'Position',[380 275 450 305]);
    add_block([lib 'Math Operations/Sum'],[m '/SumVdot'], ...
        'Inputs','+-','Position',[490 150 520 190]);
    add_block([lib 'Continuous/Integrator'],[m '/IntV'], ...
        'InitialCondition','0','Position',[560 150 600 190]);

    add_block([lib 'Math Operations/Gain'],[m '/GainR'], ...
        'Gain',g(Rtotal),'Position',[380 400 450 430]);
    add_block([lib 'Math Operations/Sum'],[m '/SumDi'], ...
        'Inputs','+-','Position',[490 380 520 420]);
    add_block([lib 'Math Operations/Product'],[m '/ProdDi'], ...
        'Position',[560 370 590 430]);
    add_block([lib 'Math Operations/Gain'],[m '/GainL'], ...
        'Gain',g(1/L),'Position',[630 385 700 415]);
    add_block([lib 'Continuous/Integrator'],[m '/IntI'], ...
        'InitialCondition','0','Position',[740 385 780 425]);

    add_block([lib 'Math Operations/Product'],[m '/Square'], ...
        'Position',[840 470 870 530]);
    add_block([lib 'Math Operations/Gain'],[m '/GainRp'], ...
        'Gain',g(Rp),'Position',[900 485 970 515]);
    add_block([lib 'Continuous/Integrator'],[m '/IntE'], ...
        'InitialCondition','0','Position',[1010 485 1050 525]);

    names = {'vc_log','i_log','E_log'};
    positions = {[680 220 750 250],[840 330 910 360],[1100 560 1170 590]};
    blocks = {'ToWs_vc','ToWs_i','ToWs_E'};
    for k = 1:3
        add_block([lib 'Sinks/To Workspace'],[m '/' blocks{k}], ...
            'VariableName',names{k},'SaveFormat','Timeseries', ...
            'Position',positions{k});
    end

    ln = @(a,b) add_line(m,a,b,'autorouting','on');
    ln('One/1','SumNS/1');
    ln('ShockSwitch/1','SumNS/2');
    ln('Vs/1','SumV/1');
    ln('IntV/1','SumV/2');
    ln('SumV/1','GainCharge/1');
    ln('GainCharge/1','ProdCharge/1');
    ln('ShockSwitch/1','ProdCharge/2');
    ln('SumNS/1','ProdDis/1');
    ln('IntI/1','ProdDis/2');
    ln('ProdDis/1','GainC/1');
    ln('ProdCharge/1','SumVdot/1');
    ln('GainC/1','SumVdot/2');
    ln('SumVdot/1','IntV/1');
    ln('IntI/1','GainR/1');
    ln('IntV/1','SumDi/1');
    ln('GainR/1','SumDi/2');
    ln('SumDi/1','ProdDi/1');
    ln('SumNS/1','ProdDi/2');
    ln('ProdDi/1','GainL/1');
    ln('GainL/1','IntI/1');
    ln('IntI/1','Square/1');
    ln('IntI/1','Square/2');
    ln('Square/1','GainRp/1');
    ln('GainRp/1','IntE/1');
    ln('IntV/1','ToWs_vc/1');
    ln('IntI/1','ToWs_i/1');
    ln('IntE/1','ToWs_E/1');

    set_param(m,'Solver','ode15s','StopTime',g(tStop),'MaxStep','1e-4');
    save_system(m,[m '.slx']);
end
