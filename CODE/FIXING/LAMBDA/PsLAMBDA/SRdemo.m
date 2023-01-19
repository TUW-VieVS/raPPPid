function SRdemo(action, option1);

%for help use the command 'help SuccessRate'

if nargin < 1; action  = 'initialize'; end;
if nargin < 2; option1 = 'none';       end;

switch action;

    case 'initialize'

        oldFigNumber  = watchon;

        % -----------------------------------
        % --- Create a full-screen figure ---
        % -----------------------------------
        ScreenSize    = get (0,'Screensize');
        ScreenSize(1) = ScreenSize(1)+ 2;    ScreenSize(2) = ScreenSize(2)+ 40;
        ScreenSize(3) = ScreenSize(3)-5;     ScreenSize(4) = ScreenSize(4)-90;

        figNumber = figure ('Name','Success rate computations','Position',ScreenSize,'Color',[0 0 0],'NumberTitle','off','Visible','off');
        h = uicontrol ('Style','Text', 'Units','normalized', 'FontWeight','Bold', 'Position',[0.005 0.003 0.4 0.025], 'String','Copyright 2012 Curtin University of Technology', 'HorizontalAlignment','left', ...
            'BackgroundColor',[0 0 0], 'Foregroundcolor',[1 1 1]);

        % ----------------------------------------
        % --- Information for all edit-boxes   ---
        % ----------------------------------------
        editWidth           = 0.07; %0.1;
        editHeight          = 0.03;
        editSpacing         = 0.01;
        editBackgroundColor = [1.00 1.00 1.00];
        textBackgroundColor = [0.00 0.596 1.00]; %0 0.70 0.70];

        % --------------------------------------
        % --- frame for basic information    ---
        % --------------------------------------
        frmBorder      = 0.015;
        frmPosition    = zeros(1,4);
        leftborder     = 0.18;
        frmPosition(1) = leftborder;
        frmPosition(2) = 1 - (8*editHeight + 7*editSpacing + 3*frmBorder);
        frmPosition(3) = 2*editWidth + 1*editSpacing + 2*frmBorder;
        frmPosition(4) = 8*editHeight + 7*editSpacing + 2*frmBorder;
        
        h = uicontrol ( 'Style','frame','Units','normalized', 'Position',frmPosition,'BackgroundColor', textBackgroundColor);     
        textLeft   = frmPosition(1) + frmBorder;
        textBottom  = 1 - 2*frmBorder - (editHeight+editSpacing);
        h = uicontrol ( 'Style','Text', 'Units','normalized', 'FontWeight','Bold', 'Position',[textLeft textBottom 2*editWidth editHeight], 'String','basic parameters', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        
        %methods
        textLeft1   = frmPosition(1) + frmBorder;
        textBottom  = 1 - 2*frmBorder - 2*(editHeight+editSpacing);
        h = uicontrol('Style','Text', 'Units','normalized', 'Position',[textLeft1 textBottom editWidth editHeight], 'String','method', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textLeft   = textLeft1 + (editWidth + editSpacing);
        h = uicontrol ('Style','Popupmenu', 'Units','normalized', 'Position',[textLeft textBottom editWidth editHeight], 'HorizontalAlignment','center', 'BackgroundColor',editBackgroundColor, 'String','ILS|bootstrapping|rounding|PAR', 'Tag','method','Value',1,'Callback',['SRdemo method']);

        %input of float solution
        filename = 'small.mat';
        textBottom = 1 - 2*frmBorder - 3*(editHeight+editSpacing);
        h = uicontrol ( 'Style','Text', 'Units','normalized', 'Position',[textLeft1 textBottom editWidth editHeight], 'String','input', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        h = uicontrol ( 'Style','Edit',  'Units','normalized', 'Position',[textLeft textBottom editWidth editHeight], 'HorizontalAlignment','left', 'BackgroundColor',editBackgroundColor, 'String', filename, 'Tag','input');
        
        %biased or not
        textBottom = 1 - 2*frmBorder - 4*(editHeight+editSpacing);
        h = uicontrol ( 'Style','Text',  'Units','normalized','Position',[textLeft1 textBottom editWidth editHeight], 'String','bias-affected',  'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        h = uicontrol ('Style','Popupmenu', 'Units','normalized', 'Position',[textLeft textBottom editWidth editHeight], 'HorizontalAlignment','center', 'BackgroundColor',editBackgroundColor, 'String', 'No|Yes', 'Tag','bias', 'Callback',['SRdemo bias'], 'Value',1);

        %nsample
        textBottom = 1 - 2*frmBorder - 5*(editHeight+editSpacing);
        h = uicontrol ('Style','Text', 'Units','normalized', 'Position',[textLeft1 textBottom editWidth editHeight], 'String','# samples', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        nsample    = 1000000;
        h = uicontrol ( 'Style','Edit', 'Units','normalized', 'Position',[textLeft textBottom editWidth-0.025, editHeight], 'HorizontalAlignment','left', 'BackgroundColor',editBackgroundColor, 'String',int2str(nsample),'Tag','nsample');
        
        %button for number of samples 
        textBottom = 1 - 2*frmBorder - 5*(editHeight+editSpacing);
        h = uicontrol ( 'Style','Push', 'Units','normalized', 'Position',[textLeft+0.05 textBottom 0.02 editHeight], 'Backgroundcolor',[0 0.82 0.82],'String', '?','Callback', 'SRdemo ''nsampact''');
         
        %decorrelation
        textBottom = 1 - 2*frmBorder - 6*(editHeight+editSpacing);
        h = uicontrol ( 'Style','Text', 'Units','normalized', 'Position',[textLeft1 textBottom editWidth editHeight], 'String','decorrelation', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        h = uicontrol ('Style','Popupmenu', 'Units','normalized', 'Position',[textLeft textBottom editWidth editHeight], 'HorizontalAlignment','center', 'BackgroundColor',editBackgroundColor, 'String', 'Yes|No', 'Tag','decor', 'Callback',['SRdemo decor'], 'Value',1);
        
        %user-defined success rate
        textBottom = 1 - 2*frmBorder - 7*(editHeight+editSpacing);
        h = uicontrol ( 'Style','Text', 'Units','normalized', 'Position',[textLeft1 textBottom editWidth editHeight], 'String','predefined success-rate', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        Ps0 = 0.99;
        h = uicontrol ('Style','Edit', 'Units','normalized', 'Position',[textLeft textBottom editWidth editHeight], 'HorizontalAlignment','left', 'BackgroundColor',editBackgroundColor, 'String','0.99','Tag','Ps0');

        % -----------------------------------
        % --- frame for ILS without bias ---
        % ----------------------------------
        frmBorder      = 0.015;
        frmPosition    = zeros(1,4);
        frmPosition(1) = 2*editWidth + editSpacing + 4*frmBorder + leftborder;
        frmPosition(2) = 1 - (8*editHeight + 7*editSpacing + 3*frmBorder);
        frmPosition(3) = 3*editSpacing + 13*frmBorder;
        frmPosition(4) = 8*editHeight + 7*editSpacing + 2*frmBorder;
        h = uicontrol ('Style','frame','Units','normalized', 'Position',frmPosition,'BackgroundColor', textBackgroundColor);

        editWidth   = 6*frmBorder;
        textLeft1   = frmBorder + frmPosition(1);
        textLeft2   = textLeft1 + 7*frmBorder; 
        
        textBottom = 1 - 2*frmBorder - (editHeight+editSpacing);
        h = uicontrol ('Style','Text','FontWeight','Bold','Units','normalized','Position',[textLeft1 textBottom 1.5*editWidth editHeight], 'String','Integer least-squares', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textBottom = 1 - 2*frmBorder - 2*(editHeight+editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft1 textBottom editWidth editHeight], 'String','simulation-based', 'BackgroundColor',textBackgroundColor, 'Tag','ILS1', 'Value',0, 'Enable','On');
        textBottom = 1 - 2*frmBorder - 3*(editHeight+editSpacing);
        h = uicontrol('Style','Text', 'FontWeight','Bold','Units','normalized','Position',[textLeft1 textBottom editWidth editHeight], 'String','Lower Bound', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textBottom = 1 - 2*frmBorder - 4*(editHeight+editSpacing);
        h = uicontrol ('Style','CheckBox', 'Units','normalized', 'Position',[textLeft1 textBottom editWidth editHeight], 'String','bootstrapping', 'BackgroundColor',textBackgroundColor, 'Tag','ILS3', 'Value',1, 'Enable','On');
        textBottom = 1 - 2*frmBorder - 5*(editHeight+editSpacing);
        h = uicontrol ('Style','CheckBox', 'Units','normalized', 'Position',[textLeft1 textBottom editWidth editHeight], 'String','bounding region','BackgroundColor',textBackgroundColor, 'Tag','ILS4', 'Value',0, 'Enable','On');
        textBottom = 1 - 2*frmBorder - 6*(editHeight+editSpacing);
        h = uicontrol ('Style','CheckBox','Units','normalized', 'Position',[textLeft1 textBottom editWidth editHeight], 'String','bounding vcv', 'BackgroundColor',textBackgroundColor, 'Tag','ILS5', 'Value',0, 'Enable','On');
        textBottom = 1 - 2*frmBorder - 2*(editHeight+editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft2 textBottom editWidth editHeight], 'String','Approx-ADOP', 'BackgroundColor',textBackgroundColor, 'Tag','ILS2', 'Value', 1,'Enable','On');
        textBottom = 1 - 2*frmBorder - 3*(editHeight+editSpacing);
        h = uicontrol('Style','Text', 'FontWeight','Bold','Units','normalized','Position',[textLeft2 textBottom editWidth editHeight], 'String','Upper Bound', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textBottom = 1 - 2*frmBorder - 4*(editHeight+editSpacing);
        h = uicontrol ('Style','CheckBox', 'Units','normalized', 'Position',[textLeft2 textBottom editWidth editHeight], 'String','ADOP', 'BackgroundColor',textBackgroundColor, 'Tag','ILS7', 'Value',0,'Enable','On');
        textBottom = 1 - 2*frmBorder - 5*(editHeight+editSpacing);
        h = uicontrol ('Style','CheckBox', 'Units','normalized', 'Position',[textLeft2 textBottom editWidth editHeight], 'String','bounding region','BackgroundColor',textBackgroundColor, 'Tag','ILS8', 'Value', 0, 'Enable','On');
        textBottom = 1 - 2*frmBorder - 6*(editHeight+editSpacing);
        h = uicontrol ('Style','CheckBox','Units','normalized', 'Position',[textLeft2 textBottom editWidth editHeight], 'String','bounding vcv', 'BackgroundColor',textBackgroundColor, 'Tag','ILS9', 'Value',0,'Enable','On');
        
        % -----------------------------------
        % --- Bootstrapping without bias ---
        % ----------------------------------- 
        frmBorder      = 0.015;
        frmPosition    = zeros(1,4);
        frmPosition(1) = 2*editWidth + 4*editSpacing + 16*frmBorder + leftborder;
        frmPosition(2) = 1 - (8*editHeight + 7*editSpacing + 3*frmBorder)+ (4*editHeight + 4*editSpacing + frmBorder);
        frmPosition(3) = 3*editSpacing + 10*frmBorder;
        frmPosition(4) = 4*editHeight + 3*editSpacing + 1*frmBorder;
        h = uicontrol ('Style','frame','Units','normalized', 'Position',frmPosition,'BackgroundColor', textBackgroundColor);
        
        editWidth     = 6*frmBorder;
        textLeft1     = frmBorder + frmPosition(1);
        textLeft2     = textLeft1 + 5*frmBorder; 
        
        textBottom = 1 - 2*frmBorder - (editHeight+editSpacing);
        h = uicontrol ('Style','Text','FontWeight','Bold','Units','normalized','Position',[textLeft1 textBottom editWidth editHeight], 'String','Bootstrapping', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textBottom = 1 - 2*frmBorder - 2*(editHeight+editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft1 textBottom editWidth editHeight], 'String','exact', 'BackgroundColor',textBackgroundColor, 'Tag','boot1', 'Value', 0, 'Callback', ['SRdemo boot 1'], 'Enable','Off');
        textBottom = 1 - 2*frmBorder - 3*(editHeight+editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft1 textBottom 0.7*editWidth editHeight], 'String','Upper Bound', 'BackgroundColor',textBackgroundColor, 'Tag','boot2', 'Value',0, 'Callback', ['SRdemo boot 2'],'Enable','Off');
        
        % -----------------------------------
        % --- rounding without bias       ---
        % -----------------------------------
        frmBorder      = 0.015;
        frmPosition(2) = 1 - (8*editHeight + 7*editSpacing + 3*frmBorder);
        h = uicontrol ('Style','frame','Units','normalized', 'Position',frmPosition,'BackgroundColor', textBackgroundColor);

        textBottom    = 1 - 3*frmBorder - (5*editHeight + 5*editSpacing);
        h = uicontrol ('Style','Text','FontWeight','Bold','Units','normalized','Position',[textLeft1 textBottom editWidth editHeight], 'String','Rounding', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textBottom = 1 - 2*frmBorder - 2*(editHeight+editSpacing) - (4*editHeight+4*editSpacing+frmBorder);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft1 textBottom editWidth editHeight], 'String','simulation-based', 'BackgroundColor',textBackgroundColor, 'Tag','round1', 'Value',0, 'Callback', ['SRdemo round 1'], 'Enable','Off');
        textBottom = 1 - 2*frmBorder - 3*(editHeight+editSpacing)- (4*editHeight+4*editSpacing+frmBorder);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft1 textBottom editWidth editHeight], 'String','Lower Bound', 'BackgroundColor',textBackgroundColor, 'Tag','round2', 'Value',0, 'Callback', ['SRdemo round 2'], 'Enable','Off');
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft2 textBottom 0.8*editWidth editHeight], 'String','Upper Bound', 'BackgroundColor',textBackgroundColor, 'Tag','round3', 'Value',0, 'Callback', ['SRdemo round 3'], 'Enable','Off');
        
        % ---------------------------
        % --- ILS with bias  ---
        % ---------------------------
        width          = 0.7*editWidth  + 1.3*editSpacing  + 3.3*frmBorder;
        height         = 5*editHeight + 4*editSpacing;
        
        frmPosition(1) = leftborder;
        frmPosition(2) = 1 - (8*editHeight + 7*editSpacing + 5*frmBorder) - height;
        frmPosition(3) = width;
        frmPosition(4) = height;
        h = uicontrol ('Style','frame','Units','normalized', 'Position',frmPosition,'BackgroundColor', textBackgroundColor);

        textLeft     = frmBorder + frmPosition(1);
        textBottom   = frmPosition(2) + frmPosition(4) - editHeight - frmBorder;
        h = uicontrol ('Style','Text','FontWeight','Bold','Units','normalized','Position',[textLeft textBottom 1.1*editWidth editHeight], 'String','bias-affected ILS', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textBottom   = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom editWidth editHeight], 'String','simulation-based', 'BackgroundColor',textBackgroundColor, 'Tag','biasILS1', 'Value',0, 'Enable','Off');
        textBottom = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom editWidth editHeight], 'String','Lower Bound', 'BackgroundColor',textBackgroundColor, 'Tag','biasILS2', 'Value',0,  'Enable','Off');
        textBottom = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom editWidth editHeight], 'String','Upper Bound', 'BackgroundColor',textBackgroundColor, 'Tag','biasILS3', 'Value',0, 'Enable','Off');
        
        % ----------------------------------
        % --- bootstrapping with bias  ---
        % ---------------------------------
        frmPosition(1) = frmPosition(1) + width + 2*frmBorder;
        frmPosition(2) = 1 - (8*editHeight + 7*editSpacing + 5*frmBorder) - height;
        frmPosition(3) = width;
        frmPosition(4) = height;
        h = uicontrol ('Style','frame','Units','normalized', 'Position',frmPosition,'BackgroundColor', textBackgroundColor);
        
        textLeft     = frmBorder + frmPosition(1);
        textBottom   = frmPosition(2) + frmPosition(4) - editHeight - frmBorder;
        h = uicontrol ('Style','Text','FontWeight','Bold','Units','normalized','Position',[textLeft textBottom 1.2*editWidth editHeight], 'String','bias-affected bootstrap', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textBottom   = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom editWidth editHeight], 'String','exact', 'BackgroundColor',textBackgroundColor, 'Tag','biasboot1', 'Value',0, 'Callback', ['SRdemo biasboot 1'], 'Enable','Off');
        textBottom = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom editWidth editHeight], 'String','Lower Bound', 'BackgroundColor',textBackgroundColor, 'Tag','biasboot2', 'Value',0, 'Callback', ['SRdemo biasboot 2'], 'Enable','Off');
        textBottom = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom editWidth editHeight], 'String','Upper Bound', 'BackgroundColor',textBackgroundColor, 'Tag','biasboot3', 'Value',0, 'Callback', ['SRdemo biasboot 3'], 'Enable','Off');
        
        % ----------------------------------
        % --- bootstrapping with bias  ---
        % ---------------------------------
        frmPosition(1) = frmPosition(1) + width + 2*frmBorder;
        frmPosition(2) = 1 - (8*editHeight + 7*editSpacing + 5*frmBorder) - height;
        frmPosition(3) = width;
        frmPosition(4) = height;
        h = uicontrol('Style','frame','Units','normalized', 'Position',frmPosition,'BackgroundColor', textBackgroundColor);
        
        textLeft     = frmBorder + frmPosition(1);
        textBottom   = frmPosition(2) + frmPosition(4) - editHeight - frmBorder;
        h = uicontrol('Style','Text','FontWeight','Bold','Units','normalized','Position',[textLeft textBottom 1.2*editWidth editHeight], 'String','bias-affected rounding', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textBottom   = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom editWidth editHeight], 'String','simulation-based', 'BackgroundColor',textBackgroundColor, 'Tag','biasround1', 'Value',0, 'Callback', ['SRdemo biasround 1'], 'Enable','Off');
        textBottom = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom editWidth editHeight], 'String','Lower Bound', 'BackgroundColor',textBackgroundColor, 'Tag','biasround2', 'Value',1, 'Callback', ['SRdemo biasround 2'], 'Enable','Off');
        textBottom = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom editWidth editHeight], 'String','Upper Bound', 'BackgroundColor',textBackgroundColor, 'Tag','biasround3', 'Value',0, 'Callback', ['SRdemo biasround 3'], 'Enable','Off');
        
        % ------------------------------------------
        % --- Information for all action buttons ---
        % ------------------------------------------
        LabelColor = [0.8 0.8 0.8];
        yInitPos   = 0.90;
        xPos       = 0.88;
        btnWidth   = editWidth*0.6;
        btnHeight  = 0.04;
        btnSpacing = 0.01;
        
        frmBorder      = 0.015;
        frmPosition(1) = 2*editWidth + 4*editSpacing + 16*frmBorder + leftborder;
        frmPosition(2) = 1 - (8*editHeight + 7*editSpacing + 3*frmBorder) - 2*frmBorder - height;
        frmPosition(3) = 3*editSpacing + 10*frmBorder;
        frmPosition(4) = height;
        h = uicontrol ('Style','frame', 'Units','normalized', 'Position',frmPosition, 'BackgroundColor', textBackgroundColor);
        % --- Close button ---
        btnLeft     = frmPosition(1) + 0.04 + btnWidth + btnSpacing;
        btnBottom   = frmPosition(2) + 1*editHeight;
        btnPosition = [btnLeft btnBottom btnWidth btnHeight];
        CloseHndl   = uicontrol ('Style','Push', 'Units','normalized', 'Position',btnPosition,'Backgroundcolor',[0 0.82 0.82], 'String','CLOSE','Callback','close(gcf)');
        % --- Info button ---
        btnBottom1  = frmPosition(2) + frmBorder + 3*editHeight;
        btnPosition = [btnLeft btnBottom1 btnWidth btnHeight];
        InfoHndl = uicontrol ( 'Style','Push', 'Units','normalized', 'Position',btnPosition,'Backgroundcolor',[0 0.82 0.82], 'String','HELP','Callback','SRdemo ''about''');
        % --- defaults button ---
        btnLeft     = frmPosition(1) + 0.02;
        btnPosition = [btnLeft btnBottom btnWidth btnHeight];
        defaHndl = uicontrol ('Style','Push', 'Units','normalized', 'Position',btnPosition,'String','DEFAULTS','Backgroundcolor',[0 0.82 0.82],'Callback','SRdemo ''default''');
        % --- compute ---
        btnPosition = [btnLeft btnBottom1 btnWidth btnHeight];
        compHndl = uicontrol ( 'Style','Push','Units','normalized','Backgroundcolor',[0 0.82 0.82], 'Position',btnPosition, 'String','COMPUTE', 'Callback','SRdemo ''compute''');
        
        % ----------------
        % --- outputs  ---
        width          = 3*editWidth  + editSpacing  + 10.5*frmBorder;
        height         = 8*editHeight + 5*editSpacing;
        bottomabove    = 1 - 13*editHeight - 11*editSpacing - 5*frmBorder;
        frmPosition(1) = leftborder;
        frmPosition(2) = bottomabove - 2*frmBorder - height;
        frmPosition(3) = width;
        frmPosition(4) = height;

        h = uicontrol ('Style','frame', 'Units','normalized', 'Position',frmPosition, 'BackgroundColor', textBackgroundColor);
        textLeft   = frmPosition(1) + frmBorder;
        textBottom = frmPosition(2) + frmBorder;
        h = uicontrol ('Style','Edit', 'Units','normalized', 'Position',[textLeft textBottom width-2*frmBorder height-2*frmBorder-editHeight], 'HorizontalAlignment','left', 'Max',100,'BackgroundColor', editBackgroundColor, 'Tag','vcv');
        textBottom = textBottom + height-2*frmBorder-editHeight;
        h = uicontrol ('Style','Text', 'Units','normalized', 'FontWeight','bold', 'Position',[textLeft textBottom 2*editWidth editHeight], 'String','variance-covariance matrix', 'BackgroundColor', textBackgroundColor,'HorizontalAlignment','left');
        
        width          = 1.5*editWidth  + editSpacing  + 2.3*frmBorder;
        frmPosition(1) = leftborder + 3*editWidth + editSpacing + 12*frmBorder;
        frmPosition(3) = width;
        frmPosition(4) = height;
        h = uicontrol ('Style','frame', 'Units','normalized', 'Position',frmPosition, 'BackgroundColor', textBackgroundColor);
        textLeft   = frmPosition(1) + frmBorder;
        textBottom = frmPosition(2) + frmBorder;
        h = uicontrol ('Style','Edit', 'Units','normalized','Fontname','Monospaced', 'Position',[textLeft textBottom width-2*frmBorder height-2*frmBorder-editHeight],'HorizontalAlignment', 'left', 'Max',100, 'BackgroundColor', editBackgroundColor, 'Tag','output');
        textBottom = textBottom + height-2*frmBorder-editHeight;
        h = uicontrol ('Style','Text', 'Units','normalized', 'FontWeight','bold', 'Position',[textLeft textBottom 1.5*editWidth editHeight], 'String','Success rate results', 'BackgroundColor', textBackgroundColor,'HorizontalAlignment','left');
        
        % --------------------------------
        % --- activate user-interface ----
        % --------------------------------
        
        hndlList=[CloseHndl InfoHndl];
        set(figNumber,'Visible','on','UserData',hndlList);
        
        watchoff(oldFigNumber);
        figure(figNumber);
        
        FileName = get(findobj (gcf,'Tag','input'),'String');
        FileName = deblank(FileName);
        if ~isempty(FileName)
            load(FileName);
            if exist('Q')
                m = size(Q,1);
                string(1:m, 1:10*m) = ' ';
                for i = 1 : m
                    for j = 1: m
                        string(i,10*(j-1)+1:10*j) = sprintf ('%8.5f%s',Q(i,j),'  ');
                    end
                end
                
                bias = get(findobj(gcf,'Tag','bias'),'Value');
                if bias == 1
                    h = findobj (gcf,'Tag','vcv');
                    set (h,'String', string);
                elseif bias==2       %biased
                    if ~exist('b')
                        for j = 1: m
                            bstring(j, 1:7) = '    0.00';
                        end
                    else
                        for j = 1: m
                            bstring(j, 1:12) = sprintf('%s%8.5f%s','    ', b(j));
                        end
                    end
                    h = findobj (gcf,'Tag','vcv');
                    set (h,'String', [string bstring]);
                end
            end
        end
        
    case 'compute'
        FileName = get (findobj (gcf,'Tag','input'),'String');
        load (FileName);
        if (~exist('Q'))
            msgbox('Incorrect input file');
            return;
        end
        bias   = get(findobj(gcf,'Tag','bias'),'Value');
        if bias==2 && (~exist('b'))   %biased
            msgbox('no bias vector, take zero vector!');
            m = size(Q,1);  b = zeros(m,1);
        end
             
        method  = get(findobj(gcf,'Tag','method'), 'Value');
        decor   = get(findobj(gcf,'Tag','decor'),'Value');
        Ps0     = get(findobj(gcf,'Tag','Ps0'),'String');      Ps0   = str2num(Ps0);
        nsamp   = get(findobj(gcf,'Tag','nsample'),'String');  nsamp = str2num(nsamp );
        
        Qa = Q;  clear Q
        
        if(bias == 1)
            mopt = [];   decor = 1;  Ps = [];  ii = 0;
            if method ==1      %ILS
                if get (findobj (gcf,'Tag','ILS1'),'Value'); mopt = [mopt 1]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:10)='Simulation';       end;
                if get (findobj (gcf,'Tag','ILS2'),'Value'); mopt = [mopt 2]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:11)='Approx-ADOP';      end;
                if get (findobj (gcf,'Tag','ILS3'),'Value'); mopt = [mopt 3]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:13)='LB-bootstrap ';    end;
                if get (findobj (gcf,'Tag','ILS4'),'Value'); mopt = [mopt 4]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:15)='LB-bound region';  end;
                if get (findobj (gcf,'Tag','ILS5'),'Value'); mopt = [mopt 5]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:13)='LB-bound VCV ';    end;
                if get (findobj (gcf,'Tag','ILS7'),'Value'); mopt = [mopt 6]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:7) ='UB-ADOP';          end;
                if get (findobj (gcf,'Tag','ILS8'),'Value'); mopt = [mopt 7]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:15)='UB-bound region';  end;
                if get (findobj (gcf,'Tag','ILS9'),'Value'); mopt = [mopt 8]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:12)='UB-bound VCV';     end;
                watchon;
                numopt=length(mopt);
                for i = 1:numopt
%                     if mopt(i)==1   %simulation with progress bar
%                         h=waitbar(0,'Simulation computation, please wait..');   %initialization progressbar
%                         ncorr = 0; nprog = 50;
%                         step = fix(nsamp/nprog);
%                         nsampnew = nsamp - step*nprog;
%                         if nsampnew>0,  nprog = nprog + 1; end
%                         for j = 1 : nprog
%                             if nsampnew>0 & j==nprog
%                                 Ps = SuccessRate(Qa, method, mopt(i), decor, nsampnew);
%                                 ncorr = ncorr + Ps * nsampne;
%                             else
%                                 Ps = SuccessRate(Qa, method, mopt(i), decor, step);
%                                 ncorr = ncorr + Ps * step;
%                             end
%                             waitbar(j/nprog);          %setting progressbar
%                         end
%                         Ps(i) = ncorr/nsamp;
%                         close(h);
%                     else
                        Ps(i) = SuccessRate(Qa, method, mopt(i), decor, nsamp);
%                     end
                end
                watchoff;
            elseif method == 2 %bootstrap
                if get (findobj (gcf,'Tag','boot1'),'Value'); mopt = [mopt 1]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:18)='Exact success-rate'; end;
                if get (findobj (gcf,'Tag','boot2'),'Value'); mopt = [mopt 2]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:7)='UB-ADOP';      end;
                
                watchon;
                numopt=length(mopt);
                if (numopt == 2)
                    Ps = SuccessRate(Qa, method, 3, decor, nsamp);
                else
                    for i = 1:numopt
                        Ps(i) = SuccessRate(Qa, method, mopt(i), decor, nsamp);
                    end
                end
                watchoff;
            elseif method ==3               %round
                if get (findobj (gcf,'Tag','round1'),'Value'); mopt = [mopt 1]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:10)='Simulation'; end;
                if get (findobj (gcf,'Tag','round2'),'Value'); mopt = [mopt 2]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:8)='LB-round'; end;
                if get (findobj (gcf,'Tag','round3'),'Value'); mopt = [mopt 3]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:12)='UB-bootstrap'; end;
                
                watchon;
                numopt=length(mopt);
                for i = 1:numopt
%                     if mopt(i)==1   %simulation with progress bar
%                         h=waitbar(0,'Simulation computation, please wait..');   %initialization progressbar
%                         ncorr = 0; nprog = 50;
%                         step = fix(nsamp/nprog);
%                         nsampnew = nsamp - step*nprog;
%                         if nsampnew>0,  nprog = nprog + 1; end
%                         for j = 1 : nprog
%                             if nsampnew>0 && j==nprog
%                                 Ps = SuccessRate(Qa, method, mopt(i), decor, nsampnew);
%                                 ncorr = ncorr + Ps * nsampne;
%                             else
%                                 Ps = SuccessRate(Qa, method, mopt(i), decor, step);
%                                 ncorr = ncorr + Ps * step;
%                             end
%                             waitbar(j/nprog);          %setting progressbar
%                         end
%                         Ps(i) = ncorr/nsamp;
%                         close(h);
%                     else
                        Ps(i) = SuccessRate(Qa,method,mopt(i),decor, nsamp);
%                     end
                end
                watchoff;
            else                  %PAR
                watchon;
                numopt = 1;
                [Ps, npar] = SuccessRate(Qa, method, 1, decor, nsamp, Ps0);
                string(1,1:27)=' '; string(1,1:10)='Partial AR';
                
                string(2,1:27)=' '; string(2,1:7)='# fixed';
                string(2,22:27) = sprintf ('%6d', npar);
                if npar == 0, Ps = 0; end
                watchoff;
            end
        end
        
        if (bias == 2)
            mopt = [];   decor = 1;  Ps = [];  ii= 0;
            if method ==1             %ILS
                if get (findobj (gcf,'Tag','biasILS1'),'Value'); mopt = [mopt 1]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:10)='Simulation'; end;
                if get (findobj (gcf,'Tag','biasILS2'),'Value'); mopt = [mopt 2]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:11)='Lower bound'; end;
                if get (findobj (gcf,'Tag','biasILS3'),'Value'); mopt = [mopt 3]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:11)='Upper bound'; end;
                
                watchon;
                numopt=length(mopt);
                for i = 1:numopt
%                     if mopt(i)==1
%                         h=waitbar(0,'Simulation computation, please wait..');   %initialization progressbar
%                         ncorr = 0; nprog = 50;
%                         step = fix(nsamp/nprog);
%                         nsampnew = nsamp - step*nprog;
%                         if nsampnew>0,  nprog = nprog + 1; end
%                         for j = 1 : nprog
%                             if nsampnew>0 & j==nprog
%                                 Ps = SuccessRateBias(Qa, method, b, mopt(i), decor, nsampnew);
%                                 ncorr = ncorr + Ps * nsampne;
%                             else
%                                 Ps = SuccessRateBias(Qa, method, b, mopt(i), decor, step);
%                                 ncorr = ncorr + Ps * step;
%                             end
%                             waitbar(j/nprog);          %setting progressbar
%                         end
%                         Ps(i) = ncorr/nsamp;
%                         close(h);
%                     else
                        Ps(i) = SuccessRateBias(Qa, method, b, mopt(i), decor, nsamp);
%                     end
                end
                watchoff;
            elseif method == 2          %bootstrap
                if get (findobj (gcf,'Tag','biasboot1'),'Value'); mopt = [mopt 1]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:18)='Exact success-rate';  end;
                if get (findobj (gcf,'Tag','biasboot2'),'Value'); mopt = [mopt 2]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:11)='Lower bound';  end;
                if get (findobj (gcf,'Tag','biasboot3'),'Value'); mopt = [mopt 3]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:11)='Upper bound';  end;
                
                watchon;
                numopt=length(mopt);
                if (numopt == 3)
                    Ps = SuccessRateBias(Qa, method, b, 4, decor, nsamp);
                else
                    for i = 1:numopt
                        Ps(i) = SuccessRateBias(Qa, method, b, mopt(i), decor, nsamp);
                    end
                end
                watchoff;
            elseif method == 3               %round
                if get (findobj (gcf,'Tag','biasround1'),'Value'); mopt = [mopt 1]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:10)='Simulation';   end;
                if get (findobj (gcf,'Tag','biasround2'),'Value'); mopt = [mopt 2]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:11)='Lower bound';  end;
                if get (findobj (gcf,'Tag','biasround3'),'Value'); mopt = [mopt 3]; ii=ii+1; string(ii,1:27)=' '; string(ii,1:11)='Upper bound';  end;
                
                watchon;
                numopt=length(mopt);
         
                for i = 1:numopt
%                     if mopt(i)==1
%                         h=waitbar(0,'Simulation computation, please wait..');   %initialization progressbar
%                         ncorr = 0; nprog = 50;
%                         step = fix(nsamp/nprog);
%                         nsampnew = nsamp - step*nprog;
%                         if nsampnew>0,  nprog = nprog + 1; end
%                         for j = 1 : nprog
%                             if nsampnew>0 & j==nprog
%                                 Ps = SuccessRateBias(Qa, method, b, mopt(i), decor, nsampnew);
%                                 ncorr = ncorr + Ps * nsampne;
%                             else
%                                 Ps = SuccessRateBias(Qa, method, b, mopt(i), decor, step);
%                                 ncorr = ncorr + Ps * step;
%                             end
%                             waitbar(j/nprog);          %setting progressbar
%                         end
%                         Ps(i) = ncorr/nsamp;
%                         close(h);
%                     else
                        Ps(i) = SuccessRateBias(Qa, method, b, mopt(i), decor, nsamp);
%                     end
                end
                watchoff;
            end
        end
        
        %Output the computed success-rate
        for j = 1:numopt
            if (Ps(j)<0)
                string(j,21:27) = sprintf ('%5.4f',Ps(j));
            else
                string(j,22:27) = sprintf ('%5.4f',Ps(j));
            end
        end;
        string
        h = findobj (gcf,'Tag','output');
        set (h,'String',string);
    case 'method'
        
        method = get(findobj(gcf,'Tag','method'), 'Value');
        set(findobj(gcf,'Tag','method'),'Value', method);
        bias = get(findobj (gcf,'Tag','bias'),'Value');
        
        switch method;
            case 1;        %ILS
                if bias==1     %ILS without bias
                    h=findobj(gcf,'Tag','ILS1');   set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS1'),'Value',0);
                    h=findobj(gcf,'Tag','ILS2');   set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS2'),'Value',1);
                    h=findobj(gcf,'Tag','ILS3');   set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS3'),'Value',1);
                    h=findobj(gcf,'Tag','ILS4');   set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS4'),'Value',0);
                    h=findobj(gcf,'Tag','ILS5');   set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS5'),'Value',0);
                    h=findobj(gcf,'Tag','ILS7');   set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS7'),'Value',1);
                    h=findobj(gcf,'Tag','ILS8');   set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS8'),'Value',0);
                    h=findobj(gcf,'Tag','ILS9');   set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS9'),'Value',0);
                    %ILS with bias
                    set (findobj(gcf,'Tag','biasILS1'),'Enable','Off');    set (findobj(gcf,'Tag','biasILS2'),'Enable','Off');
                    set (findobj(gcf,'Tag','biasILS3'),'Enable','Off');
                else
                    %ILS without bias
                    set (findobj(gcf,'Tag','ILS1'),'Enable','Off');  set (findobj(gcf,'Tag','ILS2'),'Enable','Off');
                    set (findobj(gcf,'Tag','ILS3'),'Enable','Off');  set (findobj(gcf,'Tag','ILS4'),'Enable','Off');
                    set (findobj(gcf,'Tag','ILS5'),'Enable','Off');  set (findobj(gcf,'Tag','ILS7'),'Enable','Off');
                    set (findobj(gcf,'Tag','ILS8'),'Enable','Off');  set (findobj(gcf,'Tag','ILS9'),'Enable','Off');
                    %ILS with bias
                    h=findobj(gcf,'Tag','biasILS1');  set (h,'Enable','On');  set(findobj(gcf,'Tag','biasILS1'),'Value',0);
                    h=findobj(gcf,'Tag','biasILS2');  set (h,'Enable','On');  set(findobj(gcf,'Tag','biasILS2'),'Value',1);
                    h=findobj(gcf,'Tag','biasILS3');  set (h,'Enable','On');  set(findobj(gcf,'Tag','biasILS3'),'Value',1);
                end
                %Integer Bootstrap without bias
                set (findobj(gcf,'Tag','boot1'),'Enable','Off');   set (findobj(gcf,'Tag','boot2'),'Enable','Off');
                %Integer round without bias
                h=findobj(gcf,'Tag','round1');           set (h,'Enable','Off');
                h=findobj(gcf,'Tag','round2');           set (h,'Enable','Off');
                h=findobj(gcf,'Tag','round3');           set (h,'Enable','Off');
                %Integer Bootstrap with bias
                h=findobj(gcf,'Tag','biasboot1');        set (h,'Enable','Off');
                h=findobj(gcf,'Tag','biasboot2');        set (h,'Enable','Off');
                h=findobj(gcf,'Tag','biasboot3');        set (h,'Enable','Off');
                %Integer round with bias
                h=findobj(gcf,'Tag','biasround1');       set (h,'Enable','Off');
                h=findobj(gcf,'Tag','biasround2');       set (h,'Enable','Off');
                h=findobj(gcf,'Tag','biasround3');       set (h,'Enable','Off');
            case 2     %IB
                %ILS without bias
                h=findobj(gcf,'Tag','ILS1');          set (h,'Enable','Off');
                h=findobj(gcf,'Tag','ILS2');          set (h,'Enable','Off');
                h=findobj(gcf,'Tag','ILS3');          set (h,'Enable','Off');
                h=findobj(gcf,'Tag','ILS4');          set (h,'Enable','Off');
                h=findobj(gcf,'Tag','ILS5');          set (h,'Enable','Off');
                h=findobj(gcf,'Tag','ILS7');          set (h,'Enable','Off');
                h=findobj(gcf,'Tag','ILS8');          set (h,'Enable','Off');
                h=findobj(gcf,'Tag','ILS9');          set (h,'Enable','Off');
                
                %ILS with bias
                h=findobj(gcf,'Tag','biasILS1');     set (h,'Enable','Off');
                h=findobj(gcf,'Tag','biasILS2');     set (h,'Enable','Off');
                h=findobj(gcf,'Tag','biasILS3');     set (h,'Enable','Off');
                if bias==1
                    %IBootstrap without bias
                    h=findobj(gcf,'Tag','boot1');             set (h,'Enable','On');  set(findobj(gcf,'Tag','boot1'),'Value',1);
                    h=findobj(gcf,'Tag','boot2');             set (h,'Enable','On');  set(findobj(gcf,'Tag','boot2'),'Value',0);
                    %Integer Bootstrap with bias
                    h=findobj(gcf,'Tag','biasboot1');         set (h,'Enable','Off');
                    h=findobj(gcf,'Tag','biasboot2');         set (h,'Enable','Off');
                    h=findobj(gcf,'Tag','biasboot3');         set (h,'Enable','Off');
                else
                    %Integer Bootstrap without bias
                    h=findobj(gcf,'Tag','boot1');             set (h,'Enable','Off');
                    h=findobj(gcf,'Tag','boot2');             set (h,'Enable','Off');
                    %Integer Bootstrap with bias
                    h=findobj(gcf,'Tag','biasboot1');         set (h,'Enable','On');  set(findobj(gcf,'Tag','biasboot1'),'Value',1);
                    h=findobj(gcf,'Tag','biasboot2');         set (h,'Enable','On');  set(findobj(gcf,'Tag','biasboot2'),'Value',0);
                    h=findobj(gcf,'Tag','biasboot3');         set (h,'Enable','On');  set(findobj(gcf,'Tag','biasboot3'),'Value',0);
                end
                %Integer round without bias
                h=findobj(gcf,'Tag','round1');                set (h,'Enable','Off');
                h=findobj(gcf,'Tag','round2');                set (h,'Enable','Off');
                h=findobj(gcf,'Tag','round3');                set (h,'Enable','Off');
                %Integer round with bias
                set (findobj(gcf,'Tag','biasround1'),'Enable','Off'); set (findobj(gcf,'Tag','biasround2'),'Enable','Off');  set (findobj(gcf,'Tag','biasround3'),'Enable','Off');
                
            case 3
                %Integer LS without bias
                set (findobj(gcf,'Tag','ILS1'),'Enable','Off');    set (findobj(gcf,'Tag','ILS2'),'Enable','Off');    set (findobj(gcf,'Tag','ILS3'),'Enable','Off');
                set (findobj(gcf,'Tag','ILS4'),'Enable','Off');    set (findobj(gcf,'Tag','ILS5'),'Enable','Off');    
                set (findobj(gcf,'Tag','ILS7'),'Enable','Off');    set (findobj(gcf,'Tag','ILS8'),'Enable','Off');    set (findobj(gcf,'Tag','ILS9'),'Enable','Off');
                %Integer Bootstrap without bias
                set (findobj(gcf,'Tag','boot1'),'Enable','Off');   set (findobj(gcf,'Tag','boot2'),'Enable','Off');
                %Integer LS with bias
                set (findobj(gcf,'Tag','biasILS1'),'Enable','Off');  set (findobj(gcf,'Tag','biasILS2'),'Enable','Off');  set (findobj(gcf,'Tag','biasILS3'),'Enable','Off');
                %Integer Bootstrap with bias
                set (findobj(gcf,'Tag','biasboot1'),'Enable','Off'); set (findobj(gcf,'Tag','biasboot2'),'Enable','Off'); set (findobj(gcf,'Tag','biasboot3'),'Enable','Off');
                
                if bias==1
                    %Integer round without bias
                    h=findobj(gcf,'Tag','round1');   set (h,'Enable','On');  set(h,'Value',0);
                    h=findobj(gcf,'Tag','round2');   set (h,'Enable','On');  set(h,'Value',0);
                    h=findobj(gcf,'Tag','round3');   set (h,'Enable','On');  set(h,'Value',1);
                    %Integer round with bias
                    set (findobj(gcf,'Tag','biasround1'),'Enable','Off'); set (findobj(gcf,'Tag','biasround2'),'Enable','Off'); set (findobj(gcf,'Tag','biasround3'),'Enable','Off');
                else
                    %Integer round without bias
                    h=findobj(gcf,'Tag','round1');       set (h,'Enable','Off');
                    h=findobj(gcf,'Tag','round2');       set (h,'Enable','Off');
                    h=findobj(gcf,'Tag','round3');       set (h,'Enable','Off');
                    %Integer round with bias
                    h=findobj(gcf,'Tag','biasround1');   set (h,'Enable','On');  set(h,'Value',0);
                    h=findobj(gcf,'Tag','biasround2');   set (h,'Enable','On');  set(h,'Value',1);
                    h=findobj(gcf,'Tag','biasround3');   set (h,'Enable','On');  set(h,'Value',0);
                end
            case 4
                %Integer LS
                set (findobj(gcf,'Tag','ILS1'),'Enable','Off');     set (findobj(gcf,'Tag','ILS2'),'Enable','Off');      set (findobj(gcf,'Tag','ILS3'),'Enable','Off');
                set (findobj(gcf,'Tag','ILS4'),'Enable','Off');     set (findobj(gcf,'Tag','ILS5'),'Enable','Off');     
                set (findobj(gcf,'Tag','ILS7'),'Enable','Off');     set (findobj(gcf,'Tag','ILS8'),'Enable','Off');      set (findobj(gcf,'Tag','ILS9'),'Enable','Off');
                set (findobj(gcf,'Tag','biasILS1'),'Enable','Off');  set (findobj(gcf,'Tag','biasILS2'),'Enable','Off'); set (findobj(gcf,'Tag','biasILS3'),'Enable','Off');
                
                %Integer Bootstrap
                set (findobj(gcf,'Tag','boot1'),'Enable','Off');      set (findobj(gcf,'Tag','boot2'),'Enable','Off');
                set (findobj(gcf,'Tag','biasboot1'),'Enable','Off');  set (findobj(gcf,'Tag','biasboot2'),'Enable','Off');  set (findobj(gcf,'Tag','biasboot3'),'Enable','Off');
                %Integer round
                set (findobj(gcf,'Tag','round1'),'Enable','Off');      set (findobj(gcf,'Tag','round2'),'Enable','Off');       set (findobj(gcf,'Tag','round3'),'Enable','Off');
                set (findobj(gcf,'Tag','biasround1'),'Enable','Off');  set (findobj(gcf,'Tag','biasround2'),'Enable','Off');   set (findobj(gcf,'Tag','biasround3'),'Enable','Off');
        end;
        
    case 'bias';
        
        bias = get(findobj(gcf,'Tag','bias'), 'Value');
        
        %Integer LS with bias
        h=findobj(gcf,'Tag','biasILS1');           set (h,'Enable','Off');
        h=findobj(gcf,'Tag','biasILS2');           set (h,'Enable','Off');
        h=findobj(gcf,'Tag','biasILS3');           set (h,'Enable','Off');
        h=findobj(gcf,'Tag','ILS1');               set (h,'Enable','Off');
        h=findobj(gcf,'Tag','ILS2');   set (h,'Enable','Off');
        h=findobj(gcf,'Tag','ILS3');   set (h,'Enable','Off');
        h=findobj(gcf,'Tag','ILS4');   set (h,'Enable','Off');
        h=findobj(gcf,'Tag','ILS5');   set (h,'Enable','Off');
        h=findobj(gcf,'Tag','ILS7');   set (h,'Enable','Off');
        h=findobj(gcf,'Tag','ILS8');   set (h,'Enable','Off');
        h=findobj(gcf,'Tag','ILS9');   set (h,'Enable','Off');
        
        %Integer Bootstrap with bias
        h=findobj(gcf,'Tag','biasboot1');          set (h,'Enable','Off');
        h=findobj(gcf,'Tag','biasboot2');          set (h,'Enable','Off');
        h=findobj(gcf,'Tag','biasboot3');          set (h,'Enable','Off');
        h=findobj(gcf,'Tag','boot1');              set (h,'Enable','Off');
        h=findobj(gcf,'Tag','boot2');              set (h,'Enable','Off');
        
        %Integer round with bias
        h=findobj(gcf,'Tag','biasround1');         set (h,'Enable','Off');
        h=findobj(gcf,'Tag','biasround2');         set (h,'Enable','Off');
        h=findobj(gcf,'Tag','biasround3');         set (h,'Enable','Off');
        h=findobj(gcf,'Tag','round1');             set (h,'Enable','Off');
        h=findobj(gcf,'Tag','round2');             set (h,'Enable','Off');
        h=findobj(gcf,'Tag','round3');             set (h,'Enable','Off');
        
        method = get(findobj (gcf,'Tag','method'),'Value');
                
        switch bias
            case 1    %No bias
                FileName = get(findobj (gcf,'Tag','input'),'String');
                FileName = deblank(FileName);
                if ~isempty(FileName)
                    load(FileName);
                    if exist('Q')
                        m = size(Q,1);
                        string(1:m, 1:10*m) = ' ';
                        for i = 1 : m
                            for j = 1: m
                                string(i,10*(j-1)+1:10*j) = sprintf ('%8.5f%s',Q(i,j),'  ');
                            end
                        end
                        h = findobj (gcf,'Tag','vcv');
                        set (h,'String', string);
                    end
                end
                
                if method == 1   %ILS
                    %Integer LS without bias
                    h=findobj(gcf,'Tag','ILS1');   set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS1'),'Value',0);
                    h=findobj(gcf,'Tag','ILS2');   set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS2'),'Value',1);
                    h=findobj(gcf,'Tag','ILS3');   set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS3'),'Value',1);
                    h=findobj(gcf,'Tag','ILS4');   set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS4'),'Value',0);
                    h=findobj(gcf,'Tag','ILS5');   set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS5'),'Value',0);
                    h=findobj(gcf,'Tag','ILS7');   set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS7'),'Value',1);
                    h=findobj(gcf,'Tag','ILS8');   set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS8'),'Value',0);
                    h=findobj(gcf,'Tag','ILS9');   set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS9'),'Value',0);
                elseif method==2   %bootstrap
                    %Integer Bootstrap without bias
                    h=findobj(gcf,'Tag','boot1');              set (h,'Enable','On');  set(findobj(gcf,'Tag','boot1'),'Value',1);
                    h=findobj(gcf,'Tag','boot2');              set (h,'Enable','On');  set(findobj(gcf,'Tag','boot2'),'Value',0);
                elseif method==3   %round
                    %Integer round without bias
                    h=findobj(gcf,'Tag','round1');             set (h,'Enable','On'); set(findobj(gcf,'Tag','round1'),'Value',0);
                    h=findobj(gcf,'Tag','round2');             set (h,'Enable','On'); set(findobj(gcf,'Tag','round2'),'Value',0);
                    h=findobj(gcf,'Tag','round3');             set (h,'Enable','On'); set(findobj(gcf,'Tag','round3'),'Value',1);
                end
            case 2   %biased
                
                FileName = get(findobj (gcf,'Tag','input'),'String');
                FileName = deblank(FileName);
                if ~isempty(FileName)
                    load(FileName);
                    if exist('Q')
                        m = size(Q,1);
                        string(1:m, 1:10*m) = ' ';
                        for i = 1 : m
                            for j = 1: m
                                string(i,10*(j-1)+1:10*j) = sprintf ('%8.5f%s',Q(i,j),'  ');
                            end
                        end
                        if ~exist('b')
                            for j = 1: m
                                bstring(j, 1:7) = '    0.00';
                            end
                        else
                            for j = 1: m
                                bstring(j, 1:12) = sprintf('%s%8.5f%s','    ', b(j));
                            end
                        end
                        h = findobj (gcf,'Tag','vcv');
                        set (h,'String', [string bstring]);
                    end
                end
                
                if method ==1   %ILS
                    %Integer LS with bias
                    h=findobj(gcf,'Tag','biasILS1');   set (h,'Enable','On');  set(findobj(gcf,'Tag','biasILS1'),'Value',0);
                    h=findobj(gcf,'Tag','biasILS2');   set (h,'Enable','On');  set(findobj(gcf,'Tag','biasILS2'),'Value',1);
                    h=findobj(gcf,'Tag','biasILS3');   set (h,'Enable','On');  set(findobj(gcf,'Tag','biasILS3'),'Value',1);
                elseif method==2 %bootstrap
                    %Integer Bootstrap with bias
                    h=findobj(gcf,'Tag','biasboot1');        set (h,'Enable','On');  set(findobj(gcf,'Tag','biasboot1'),'Value',1);
                    h=findobj(gcf,'Tag','biasboot2');        set (h,'Enable','On');  set(findobj(gcf,'Tag','biasboot2'),'Value',0);
                    h=findobj(gcf,'Tag','biasboot3');        set (h,'Enable','On');  set(findobj(gcf,'Tag','biasboot3'),'Value',0);
                elseif method ==3  %round
                    %Integer round with bias
                    h=findobj(gcf,'Tag','biasround1');       set (h,'Enable','On'); set(findobj(gcf,'Tag','biasround1'),'Value',0);
                    h=findobj(gcf,'Tag','biasround2');       set (h,'Enable','On'); set(findobj(gcf,'Tag','biasround2'),'Value',1);
                    h=findobj(gcf,'Tag','biasround3');       set (h,'Enable','On'); set(findobj(gcf,'Tag','biasround3'),'Value',1);
                end
        end;

    case 'default'
        
        set(findobj(gcf,'Tag','method'),'Value',1);
        set(findobj(gcf,'Tag','bias'),'Value',1);
        set(findobj(gcf,'Tag','decor'),'Value',1);
        set(findobj(gcf,'Tag','Ps0'), 'String', '0.99');
        
        %Integer LS with bias
        h=findobj(gcf,'Tag','ILS1');      set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS1'),'Value',0);
        h=findobj(gcf,'Tag','ILS2');      set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS2'),'Value',1);
        h=findobj(gcf,'Tag','ILS3');      set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS3'),'Value',1);
        h=findobj(gcf,'Tag','ILS4');      set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS4'),'Value',0);
        h=findobj(gcf,'Tag','ILS5');      set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS5'),'Value',0);
        h=findobj(gcf,'Tag','ILS7');      set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS7'),'Value',0);
        h=findobj(gcf,'Tag','ILS8');      set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS8'),'Value',0);
        h=findobj(gcf,'Tag','ILS9');      set (h,'Enable','On');  set(findobj(gcf,'Tag','ILS9'),'Value',0);
  
        set (findobj(gcf,'Tag','biasILS1'),'Enable','Off');    set (findobj(gcf,'Tag','biasILS2'),'Enable','Off');
        set (findobj(gcf,'Tag','biasILS3'),'Enable','Off');    set (findobj(gcf,'Tag','biasboot1'),'Enable','Off');
        set (findobj(gcf,'Tag','biasboot2'),'Enable','Off');   set (findobj(gcf,'Tag','biasboot3'),'Enable','Off');
        set (findobj(gcf,'Tag','boot1'),'Enable','Off');       set (findobj(gcf,'Tag','boot2'),'Enable','Off');
        set (findobj(gcf,'Tag','biasround1'),'Enable','Off');  set (findobj(gcf,'Tag','biasround2'),'Enable','Off');
        set (findobj(gcf,'Tag','biasround3'),'Enable','Off');  set (findobj(gcf,'Tag','round1'),'Enable','Off');
        set (findobj(gcf,'Tag','round2'),'Enable','Off');      set (findobj(gcf,'Tag','round3'),'Enable','Off');
        % call if 'HELP' button is pushed
    case 'about';
        helpwin(mfilename);
    case 'nsampact'
        
        FileName = get (findobj (gcf,'Tag','input'),'String');
        load (FileName);
        if (~exist('Q'))
            msgbox('Incorrect input file');
            return;
        end
        Qa = Q;  clear Q
        P0 = SuccessRate(Qa, 2, 1, 1, NaN);   %bootstrapped success-rate
        
        epserr = [1:5:1000]*1.0e-5;
        nerr   = length(epserr);
        nsampt = zeros(nerr, 2);
        for i = 1 : nerr
            nsampt(i,1) = cal_nsamp(P0, epserr(i), 0.01);
            nsampt(i,2) = cal_nsamp(P0, epserr(i), 0.001);
        end
        figure
        loglog(epserr, nsampt, 'Linewidth',2);
        set(gca, 'fontsize',12);
        set(gcf,'position',get(0,'screensize'));
        grid on
        legend('UB: 0.01', 'UB: 0.001');
        title('# samples required to obtain a maximum probability UB of the simulation error > \epsilon');
        xlabel('simulation error \epsilon');
        ylabel('number of samples');
%     otherwise
%         error('Illegal action, SRdemo ended');
end

