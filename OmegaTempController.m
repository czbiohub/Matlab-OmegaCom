classdef OmegaTempController < handle
    %
    % obj = InhecoMtcController(com_port, virtual)
    %
    %
    %   virtual = bool set to true for virtualized hardware
    %
 
    % Kevin Yamauchi 11/19/18
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Access = protected)
        controller % Object for talking to the Omega controller (modbus)
        
        com_port
        
        lastError = 0;
        virtual = false; % bool set to true for running with virtualized hardware
        virtual_target_temp = 0; % Last set target temp (for virtual mode only)
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Constant, Access = protected)
        % Register addresses
        
        % Current temp sensor reading
        TEMP_ADDR = struct('address', 528, 'n_reg', 2, 'type', 'single');
        
        % Current setpoint
        SETPOINT_ADDR = struct('address', 544, 'n_reg', 2, 'type',...
            'single');
        
        % Current run mode
        RUNMODE_ADDR = struct('address', 576, 'n_reg', 1, 'type', 'uint16');
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = public)
        function this = OmegaTempController(com_port, virtual)
            
            % Set the virtual arg
            if nargin > 1
                
                this.virtual = virtual;
            else
                this.virtual = false;
                
            end
            
            % Initialize the controller connection
            try
                % parse the config file and setup the modbus connection
                this.configController(com_port);

            catch ME
                try
                    delete(this.controller);
                catch
                end

                rethrow(ME);
            end
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function temp = getActualTemperature(this)
            
            if ~this.virtual
                resp = read(this.controller,'holdingregs',...
                    this.TEMP_ADDR.address, this.TEMP_ADDR.n_reg,...
                    1, this.TEMP_ADDR.type);
                
%                 if ~isempty(resp) && (numel(resp) == 9)
%                     temp = str2double(resp(5:end))/10;
%                     this.lastError = this.ERRORS.none;
%                 else
%                     this.lastErr = this.ERRORS.invalidResponse;
%                     error('Invalid response from Omega temp control');
%                 end
                
            else
                
                temp = 70 * rand();
                
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function temp = getTargetTemperature(this)
            
            if ~this.virtual
                resp = read(this.controller,'holdingregs',...
                    this.SETPOINT_ADDR.address,...
                    this.SETPOINT_ADDR.n_reg, 1, this.SETPOINT_ADDR.type);
                
%                 if ~isempty(resp) && (numel(resp) == 9)
%                     temp = str2double(resp(5:end))/10;
%                     this.lastError = this.ERRORS.none;
%                 else
%                     this.lastErr = this.ERRORS.invalidResponse;
%                     error('Invalid response from MTC');
%                 end
                
            else
               temp = this.virtual_target_temp;
                
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function setTargetTemperature(this, temp)
            
            if ~this.virtual
                % Sets target temperature and starts control in the chosen
                % block
                write(this.controller, 'holdingregs',...
                    this.SETPOINT_ADDR.address,...
                    temp, 1, this.SETPOINT_ADDR.type);
            
            % In virtual mode, save the target temp
            else
                this.virtual_target_temp = temp;
                
            end
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function startControl(this)
            
            if ~this.virtual
                % Start controlling temperature in the chosen block
                % Block will go to existing target temperature
                write(this.controller, 'holdingregs',...
                    this.RUNMODE_ADDR.address,...
                    temp, 6, this.RUNMODE_ADDR.type);
                
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function stopControl(this, blockId)
            
            if ~this.virtual
                % Stop controlling temperature in the chosen block
                write(this.controller, 'holdingregs',...
                    this.RUNMODE_ADDR.address,...
                    temp, 1, this.RUNMODE_ADDR.type);
            end
        end
        

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [err, errDescr] = getLastError(this)
            err = this.lastError;
            errDescr = 'Unknown';
            switch err
                case this.ERRORS.none
                    errDescr = 'None';
                case this.ERRORS.errorOnFind
                    errDescr = 'Error on FindTheUniversalControl';
                case this.ERRORS.errorOnWrite
                    errDescr = 'Error on WriteOnly';
                case this.ERRORS.errorOnRead
                    errDescr = 'Error on ReadSync';
                case this.ERRORS.emptyResponse
                    errDescr = 'Empty response from MTC';
                case this.ERRORS.invalidResponse
                    errDescr = 'Invalid response from MTC';
                case this.ERRORS.undefinedBlock
                    errDescr = 'Undefined block ID';
                case this.ERRORS.invalidMtcId
                    errDescr = 'Invalid MTC ID';
                case this.ERRORS.invalidSlotId
                    errDescr = 'Invalid Slot ID';
                case this.ERRORS.mtcNotFound
                    errDescr = 'MTC not found';
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Destructor
        function delete(this)
            
            if ~this.virtual
                try
                    this.enableTouchscreen();
                catch
                end
                try
                    delete(this.inheco);
                catch
                end
                try
                    delete(this.pymod);
                catch
                end
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = protected)


        function configController(this, com_port)
            this.com_port = com_port;
            
            try
                this.controller = modbus('serialrtu', this.com_port);
            
            catch
                
            end

        end
        
    end
end

