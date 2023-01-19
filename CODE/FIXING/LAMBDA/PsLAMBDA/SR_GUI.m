function SR_GUI(action, option1);

% The input file should contain the variance-covariance matrix
% of the float ambiguities, named Q
% For further help use the command 'help SuccessRate'


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
        h = uicontrol ('Style','Text', 'Units','normalized', 'FontWeight','Bold', 'Position',[0.005 0.003 0.4 0.025], 'String','Copyright 2012 Curtin University', 'HorizontalAlignment','left', ...
            'BackgroundColor',[0 0 0], 'Foregroundcolor',[1 1 1]);

        % ----------------------------------------
        % --- Information for all edit-boxes   ---
        % ----------------------------------------
        frmSpacing          = 0.12/5;
        frmWidth            = 0.22;
        frmBorder           = 0.01;
        editWidth           = 0.15; 
        editHeight          = 0.025;
        editSpacing         = 0.005;
        editBackgroundColor = [1.00 1.00 1.00];
        textBackgroundColor = [0.6 0.8 1]; 
        btnColor            = [0 0.6 0.9];

        % --------------------------------------
        % --- frame for input file           ---
        % --------------------------------------
    
        frmPosition(1) = frmSpacing;
        frmPosition(2) = 1 - (frmSpacing + editHeight + 2*frmBorder);
        frmPosition(3) = 4*frmWidth + 3*frmSpacing;
        frmPosition(4) = editHeight + 2*frmBorder;       
        h = uicontrol ( 'Style','frame','Units','normalized', 'Position',frmPosition,'BackgroundColor', textBackgroundColor); 
        %input of float solution
        textLeft   = frmPosition(1) + frmBorder;
        textBottom = frmPosition(2) + frmBorder;
        h = uicontrol ( 'Style','Text', 'Units','normalized', 'FontWeight',...
            'Bold','Position',[textLeft textBottom 0.4*editWidth editHeight], ...
            'String','Input file:', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textLeft   = textLeft + editSpacing + 0.4*editWidth;        
        h = uicontrol ( 'Style','Edit','Units','normalized',...
            'Position',[textLeft textBottom 2*editWidth editHeight],...
            'HorizontalAlignment','left', 'BackgroundColor',editBackgroundColor, ...
            'String', 'small.mat', 'Tag','InputFile');
        textLeft   = textLeft + editSpacing + 2*editWidth;        
        h = uicontrol ( 'Style','PushButton','Units','normalized',...
            'Position',[textLeft textBottom 0.4*editWidth editHeight], ...
            'HorizontalAlignment','left', 'BackgroundColor',btnColor, ...
            'String', 'browse', 'Callback','SR_GUI Selectfile');

          
        % --------------------------------------
        % --- frame for basic information    ---
        % --------------------------------------
        
        frmHeight      = 10*editHeight + 9*editSpacing + 2*frmBorder;
        frmPosition(1) = frmSpacing;
        frmPosition(2) = frmPosition(2) - frmHeight - frmSpacing  ;
        frmPosition(3) = frmWidth;
        frmPosition(4) = frmHeight;
        
        h = uicontrol ( 'Style','frame','Units','normalized', 'Position',frmPosition,'BackgroundColor', textBackgroundColor);     
        textLeft    = frmPosition(1) + frmBorder;
        textBottom  = frmPosition(2) + frmHeight - frmBorder - editHeight;
        h = uicontrol ( 'Style','Text', 'Units','normalized', 'FontWeight','Bold', 'Position',[textLeft textBottom editWidth editHeight], 'String','Information', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol ('Style','Text','Units','normalized','Position',[textLeft textBottom editWidth editHeight], 'String','AP = approximation', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol ('Style','Text','Units','normalized','Position',[textLeft textBottom editWidth editHeight], 'String','LB = lower bound', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol ('Style','Text','Units','normalized','Position',[textLeft textBottom editWidth editHeight], 'String','UB = upper bound', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);

        textBottom = textBottom - 2*(editHeight+editSpacing);
        h = uicontrol ('Style','Text','FontWeight','Bold', 'Units','normalized','Position',[textLeft textBottom 1.3*editWidth editHeight], ...
            'String','Number of samples for simulations', ...
            'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor); 
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol ('Style','Text','Units','normalized','Position',[textLeft textBottom 0.8*editWidth editHeight], ...
            'String','(recommended is 100,000):', ...
            'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor); 
        nsample    = 100000;
        h = uicontrol ( 'Style','Edit', 'Units','normalized', ...
            'Position',[frmSpacing+frmWidth-frmBorder-0.3*editWidth textBottom 0.3*editWidth editHeight],...
            'HorizontalAlignment','left', 'BackgroundColor',editBackgroundColor, 'String',int2str(nsample),'Tag','nsample');

%        
        % -----------------------------------
        % --- frame for ILS without bias ---
        % ----------------------------------
        frmPosition(1) = frmWidth + 2*frmSpacing;
        frmPosition(3) = frmWidth;
        frmPosition(4) = frmHeight;
        h = uicontrol ('Style','frame','Units','normalized', 'Position',frmPosition,'BackgroundColor', textBackgroundColor);

        textLeft   = frmBorder + frmPosition(1);        
        textBottom = frmPosition(2) + frmHeight - editHeight - frmBorder;        
        h = uicontrol ('Style','Text','FontWeight','Bold','Units','normalized','Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','Integer Least Squares', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 0.8*editWidth editHeight], 'String','AP : simulation-based', 'BackgroundColor',textBackgroundColor, 'Tag','ILS1', 'Value',0, 'Enable','On');

        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','AP : ADOP-based', 'BackgroundColor',textBackgroundColor, 'Tag','ILS2', 'Value', 0,'Enable','On');
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol ('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','LB : bootstrapping', 'BackgroundColor',textBackgroundColor, 'Tag','ILS3', 'Value',1, 'Enable','On');
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol ('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','LB : bounding region','BackgroundColor',textBackgroundColor, 'Tag','ILS4', 'Value',0, 'Enable','On');
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol ('Style','CheckBox','Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','LB : bounding vc-matrix', 'BackgroundColor',textBackgroundColor, 'Tag','ILS5', 'Value',0, 'Enable','On');
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol ('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','UB : ADOP-based', 'BackgroundColor',textBackgroundColor, 'Tag','ILS7', 'Value',0,'Enable','On');
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol ('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','UB : bounding region','BackgroundColor',textBackgroundColor, 'Tag','ILS8', 'Value', 0, 'Enable','On');
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol ('Style','CheckBox','Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','UB : bounding vc-matrix', 'BackgroundColor',textBackgroundColor, 'Tag','ILS9', 'Value',0,'Enable','On');
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol ('Style','RadioButton','Units','normalized',...
            'Position',[textLeft textBottom 1.3*editWidth editHeight],...
            'String','(de)select all', 'BackgroundColor',textBackgroundColor, ...
            'Callback',['SR_GUI select ILS'],'Tag','ILSall', 'Value',0,'Enable','On');
       
        % -----------------------------------
        % --- Bootstrapping without bias ---
        % ----------------------------------- 
        frmPosition(1) = 2*frmWidth + 3*frmSpacing;
        frmPosition(3) = frmWidth;
        frmPosition(4) = frmHeight;
        h = uicontrol ('Style','frame','Units','normalized', 'Position',frmPosition,'BackgroundColor', textBackgroundColor);
        
        textLeft   = frmBorder + frmPosition(1);        
        textBottom = frmPosition(2) + frmHeight - editHeight - frmBorder;
        h = uicontrol ('Style','Text','FontWeight','Bold','Units','normalized','Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','Bootstrapping', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);

        %decorrelation
        textBottom = textBottom- (editHeight+3*editSpacing);
        h = uicontrol ( 'Style','Text', 'Units','normalized', ...
            'Position',[textLeft textBottom 0.75*editWidth editHeight],...
            'String','Decorrelation?', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        h = uicontrol ('Style','Popupmenu', 'Units','normalized', ...
            'Position',[textLeft+0.8*editWidth textBottom 0.4*editWidth editHeight],...
            'HorizontalAlignment','center', 'BackgroundColor',editBackgroundColor,...
            'String', 'Yes|No', 'Tag','decor','Value',1);
        
             
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','EXACT', 'BackgroundColor',textBackgroundColor, 'Tag','boot1', 'Value', 1, 'Callback', ['SR_GUI boot 1'], 'Enable','On');
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','UB : ADOP-based', 'BackgroundColor',textBackgroundColor, 'Tag','boot2', 'Value',0, 'Callback', ['SR_GUI boot 2'],'Enable','On');
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol ('Style','RadioButton','Units','normalized',...
            'Position',[textLeft textBottom 1.3*editWidth editHeight],...
            'String','(de)select all', 'BackgroundColor',textBackgroundColor, ...
            'Callback',['SR_GUI select B'],'Tag','Ball', 'Value',0,'Enable','On');
        
        % -----------------------------------
        % --- rounding without bias       ---
        % -----------------------------------
        frmPosition(1) = 3*frmWidth + 4*frmSpacing;
        frmPosition(3) = frmWidth;
        frmPosition(4) = frmHeight;
        h = uicontrol ('Style','frame','Units','normalized', 'Position',frmPosition,'BackgroundColor', textBackgroundColor);

        textLeft   = frmBorder + frmPosition(1);  
        textBottom = frmPosition(2) + frmHeight - editHeight - frmBorder;
        h = uicontrol ('Style','Text','FontWeight','Bold','Units','normalized','Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','Rounding', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        %decorrelation
        textBottom = textBottom- (editHeight+3*editSpacing);
        h = uicontrol ( 'Style','Text', 'Units','normalized', 'Position',[textLeft textBottom 0.75*editWidth editHeight], 'String','Decorrelation?', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        h = uicontrol ('Style','Popupmenu', 'Units','normalized', ...
            'Position',[textLeft+0.8*editWidth textBottom 0.4*editWidth editHeight],...
            'HorizontalAlignment','center', 'BackgroundColor',editBackgroundColor,...
            'String', 'Yes|No', 'Tag','decorR','Value',1);
        
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','AP : simulation-based', 'BackgroundColor',textBackgroundColor, 'Tag','round1', 'Value',0, 'Callback', ['SR_GUI round 1'], 'Enable','On');

        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','LB', 'BackgroundColor',textBackgroundColor, 'Tag','round2', 'Value',0, 'Callback', ['SR_GUI round 2'], 'Enable','On');
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','UB', 'BackgroundColor',textBackgroundColor, 'Tag','round3', 'Value',1, 'Callback', ['SR_GUI round 3'], 'Enable','On');
        textBottom = textBottom - (editHeight+editSpacing);
        h = uicontrol ('Style','RadioButton','Units','normalized',...
            'Position',[textLeft textBottom editWidth editHeight],...
            'String','(de)select all', 'BackgroundColor',textBackgroundColor, ...
            'Callback',['SR_GUI select R'],'Tag','Rall', 'Value',0,'Enable','On');
       
        % ---------------------------
        % --- bias frame  ---
        % ---------------------------
        frmHeight      = 6*editHeight + 5*editSpacing;
        
        frmPosition(1) = frmSpacing;
        frmPosition(2) = frmPosition(2) - frmHeight - frmSpacing;
        frmPosition(3) = frmWidth;
        frmPosition(4) = frmHeight;
        h = uicontrol ('Style','frame','Units','normalized', 'Position',frmPosition,'BackgroundColor', textBackgroundColor);

        textLeft     = frmBorder + frmPosition(1);
        textBottom   = frmPosition(2) + frmPosition(4) - editHeight - frmBorder;
        h = uicontrol ('Style','Text','FontWeight','Bold','Units','normalized','Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','Bias-affected success rates', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textBottom   = textBottom - (editHeight+ editSpacing);
        h = uicontrol ('Style','Text','Units','normalized','Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','Specify the bias vector:', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textBottom   = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','RadioButton', 'Units','normalized', ...
            'Position',[textLeft textBottom 1.3*editWidth editHeight], ...
            'String','vector b from Input file', 'BackgroundColor',textBackgroundColor,...
            'Callback',['SR_GUI bias file'],'Tag','bfile', 'Value',1, 'Enable','On');
        textBottom = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','RadioButton', 'Units','normalized', ...
            'Position',[textLeft textBottom 1.3*editWidth editHeight], ...
            'String','same bias on all ambiguities equal to:', ...
            'BackgroundColor',textBackgroundColor, 'Tag','bspec',...
            'Callback',['SR_GUI bias spec'],'Value',0, 'Enable','On');
        textBottom = textBottom - (editHeight+ editSpacing);
        h = uicontrol ( 'Style','Edit', 'Units','normalized', ...
            'Position',[textLeft+0.01 textBottom 0.3*editWidth editHeight],...
            'HorizontalAlignment','left', 'BackgroundColor',editBackgroundColor,...
            'String','0.1','Tag','bcycles','Enable','Off');
        h = uicontrol ('Style','Text', 'Units','normalized', 'Position',[textLeft+0.4*editWidth+0.01 textBottom 0.4*editWidth editHeight], 'String','cycles', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
      
        % ---------------------------
        % --- ILS with bias  ---
        % ---------------------------
        
        frmPosition(1) = 2*frmSpacing  + frmWidth;
        frmPosition(3) = frmWidth;
        frmPosition(4) = frmHeight;
        h = uicontrol ('Style','frame','Units','normalized', 'Position',frmPosition,'BackgroundColor', textBackgroundColor);

        textLeft     = frmBorder + frmPosition(1);
        textBottom   = frmPosition(2) + frmPosition(4) - editHeight - frmBorder;
        h = uicontrol ('Style','Text','FontWeight','Bold','Units','normalized','Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','Bias-affected Integer Least Squares', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textBottom   = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','AP : simulation-based', 'BackgroundColor',textBackgroundColor, 'Tag','biasILS1', 'Value',0, 'Enable','On');
        textBottom = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','LB', 'BackgroundColor',textBackgroundColor, 'Tag','biasILS2', 'Value',0,  'Enable','On');
        textBottom = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','UB', 'BackgroundColor',textBackgroundColor, 'Tag','biasILS3', 'Value',0, 'Enable','On');
        textBottom = textBottom - (editHeight+ editSpacing);
        h = uicontrol ('Style','RadioButton','Units','normalized',...
            'Position',[textLeft textBottom editWidth editHeight],...
            'String','(de)select all', 'BackgroundColor',textBackgroundColor, ...
            'Callback',['SR_GUI select ILSbias'],'Tag','ILSbiasall', 'Value',0,'Enable','On');       
        % ----------------------------------
        % --- bootstrapping with bias  ---
        % ---------------------------------
        frmPosition(1) = 2*frmWidth + 3*frmSpacing;
        frmPosition(3) = frmWidth;
        frmPosition(4) = frmHeight;
        h = uicontrol ('Style','frame','Units','normalized', 'Position',frmPosition,'BackgroundColor', textBackgroundColor);
        
        textLeft     = frmBorder + frmPosition(1);
        textBottom   = frmPosition(2) + frmPosition(4) - editHeight - frmBorder;
        h = uicontrol ('Style','Text','FontWeight','Bold','Units','normalized','Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','Bias-affected bootstrapping', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textBottom   = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','EXACT', 'BackgroundColor',textBackgroundColor, 'Tag','biasboot1', 'Value',0, 'Callback', ['SR_GUI biasboot 1'], 'Enable','On');
        textBottom = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','LB', 'BackgroundColor',textBackgroundColor, 'Tag','biasboot2', 'Value',0, 'Callback', ['SR_GUI biasboot 2'], 'Enable','On');
        textBottom = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','UB', 'BackgroundColor',textBackgroundColor, 'Tag','biasboot3', 'Value',0, 'Callback', ['SR_GUI biasboot 3'], 'Enable','On');
        textBottom = textBottom - (editHeight+ editSpacing);
        h = uicontrol ('Style','RadioButton','Units','normalized',...
            'Position',[textLeft textBottom editWidth editHeight],...
            'String','(de)select all', 'BackgroundColor',textBackgroundColor, ...
            'Callback',['SR_GUI select Bbias'],'Tag','Bbiasall', 'Value',0,'Enable','On');         
        % ----------------------------------
        % --- rounding with bias  ---
        % ---------------------------------
        frmPosition(1) = 3*frmWidth + 4*frmSpacing;
%         frmPosition(2) = 1 - (9*editHeight + 8*editSpacing + 5*frmBorder) - height;
        frmPosition(3) = frmWidth;
        frmPosition(4) = frmHeight;;
        h = uicontrol('Style','frame','Units','normalized', 'Position',frmPosition,'BackgroundColor', textBackgroundColor);
        
        textLeft     = frmBorder + frmPosition(1);
        textBottom   = frmPosition(2) + frmPosition(4) - editHeight - frmBorder;
        h = uicontrol('Style','Text','FontWeight','Bold','Units','normalized','Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','Bias-affected rounding', 'HorizontalAlignment','left', 'BackgroundColor',textBackgroundColor);
        textBottom   = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','AP : simulation-based', 'BackgroundColor',textBackgroundColor, 'Tag','biasround1', 'Value',0, 'Callback', ['SR_GUI biasround 1'], 'Enable','On');
        textBottom = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','LB', 'BackgroundColor',textBackgroundColor, 'Tag','biasround2', 'Value',0, 'Callback', ['SR_GUI biasround 2'], 'Enable','On');
        textBottom = textBottom - (editHeight+ editSpacing);
        h = uicontrol('Style','CheckBox', 'Units','normalized', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','UB', 'BackgroundColor',textBackgroundColor, 'Tag','biasround3', 'Value',0, 'Callback', ['SR_GUI biasround 3'], 'Enable','On');
         textBottom = textBottom - (editHeight+ editSpacing);
        h = uicontrol ('Style','RadioButton','Units','normalized',...
            'Position',[textLeft textBottom editWidth editHeight],...
            'String','(de)select all', 'BackgroundColor',textBackgroundColor, ...
            'Callback',['SR_GUI select Rbias'],'Tag','Rbiasall', 'Value',0,'Enable','On');         
        % ------------------------------------------
        % --- Information for all action buttons ---
        % ------------------------------------------
        LabelColor = [0.8 0.8 0.8];
        yInitPos   = 0.90;
        xPos       = 0.88;
        btnWidth   = editWidth*0.6;
        btnHeight  = 0.04;
        btnSpacing = 0.02;
        
        frmHeight      = frmPosition(2) - 2*frmSpacing;
        frmPosition(1) = frmSpacing;
        frmPosition(2) = frmSpacing;
        frmPosition(3) = frmWidth;
        frmPosition(4) = frmHeight;
        % --- compute ---
        btnLeft     = frmSpacing + (frmWidth-btnWidth)/2;
        btnBottom   = frmSpacing + frmHeight -btnHeight-btnSpacing;
        btnPosition = [btnLeft btnBottom btnWidth btnHeight];
        compHndl = uicontrol ( 'Style','Push','Units','normalized','Backgroundcolor',btnColor, 'Position',btnPosition, 'String','COMPUTE', 'Callback','SR_GUI ''compute''');
        % --- Info button ---
        btnBottom   = btnBottom - btnHeight - btnSpacing;
        btnPosition = [btnLeft btnBottom btnWidth btnHeight];
        InfoHndl = uicontrol ( 'Style','Push', 'Units','normalized', 'Position',btnPosition,'Backgroundcolor',btnColor, 'String','HELP','Callback','SR_GUI ''about''');
        % --- defaults button ---
        btnBottom   = btnBottom - btnHeight - btnSpacing;
        btnPosition = [btnLeft btnBottom btnWidth btnHeight];
        defaHndl = uicontrol ('Style','Push', 'Units','normalized', 'Position',btnPosition,'String','DEFAULTS','Backgroundcolor',btnColor,'Callback','SR_GUI ''default''');
        % --- close ---
        btnBottom   = btnBottom - btnHeight - btnSpacing;
        btnPosition = [btnLeft btnBottom btnWidth btnHeight];
        CloseHndl   = uicontrol ('Style','Push', 'Units','normalized', 'Position',btnPosition,'Backgroundcolor',btnColor, 'String','CLOSE','Callback','close(gcf)');
        
        % ----------------
        % --- outputs  ---
        % ----------------
      
        frmPosition(1) = 2*frmSpacing + frmWidth ;
        frmPosition(3) = frmWidth;
        frmPosition(4) = frmHeight;
        h = uicontrol ('Style','frame', 'Units','normalized', 'Position',frmPosition, 'BackgroundColor', textBackgroundColor);
        textLeft   = frmPosition(1) + frmBorder;
        textBottom = frmPosition(2) + frmBorder;
        h = uicontrol ('Style','Edit', 'Units','normalized','Fontname','Monospaced', 'Position',[textLeft textBottom frmWidth-2*frmBorder frmHeight-2*frmBorder-editHeight],'HorizontalAlignment', 'left', 'Max',100, 'BackgroundColor', editBackgroundColor, 'Tag','outputILS');
        textBottom = textBottom + frmHeight-2*frmBorder-editHeight;
        h = uicontrol ('Style','Text', 'Units','normalized', 'FontWeight','bold', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','Integer Least Squares Success rates', 'BackgroundColor', textBackgroundColor,'HorizontalAlignment','left');
        
        frmPosition(1) = 3*frmSpacing + 2*frmWidth ;
        frmPosition(3) = frmWidth;
        frmPosition(4) = frmHeight;
        h = uicontrol ('Style','frame', 'Units','normalized', 'Position',frmPosition, 'BackgroundColor', textBackgroundColor);
        textLeft   = frmPosition(1) + frmBorder;
        textBottom = frmPosition(2) + frmBorder;
        h = uicontrol ('Style','Edit', 'Units','normalized','Fontname','Monospaced', 'Position',[textLeft textBottom frmWidth-2*frmBorder frmHeight-2*frmBorder-editHeight],'HorizontalAlignment', 'left', 'Max',100, 'BackgroundColor', editBackgroundColor, 'Tag','outputB');
        textBottom = textBottom + frmHeight-2*frmBorder-editHeight;
        h = uicontrol ('Style','Text', 'Units','normalized', 'FontWeight','bold', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','Bootstrapping Success rates', 'BackgroundColor', textBackgroundColor,'HorizontalAlignment','left');
        
        frmPosition(1) = 4*frmSpacing + 3*frmWidth ;
        frmPosition(3) = frmWidth;
        frmPosition(4) = frmHeight;
        h = uicontrol ('Style','frame', 'Units','normalized', 'Position',frmPosition, 'BackgroundColor', textBackgroundColor);
        textLeft   = frmPosition(1) + frmBorder;
        textBottom = frmPosition(2) + frmBorder;
        h = uicontrol ('Style','Edit', 'Units','normalized','Fontname','Monospaced', 'Position',[textLeft textBottom frmWidth-2*frmBorder frmHeight-2*frmBorder-editHeight],'HorizontalAlignment', 'left', 'Max',100, 'BackgroundColor', editBackgroundColor, 'Tag','outputR');
        textBottom = textBottom + frmHeight-2*frmBorder-editHeight;
        h = uicontrol ('Style','Text', 'Units','normalized', 'FontWeight','bold', 'Position',[textLeft textBottom 1.3*editWidth editHeight], 'String','Rounding Success rates', 'BackgroundColor', textBackgroundColor,'HorizontalAlignment','left');
        
        % --------------------------------
        % --- activate user-interface ----
        % --------------------------------
        
        hndlList=[CloseHndl InfoHndl];
        set(figNumber,'Visible','on','UserData',hndlList);
        
%         watchoff(oldFigNumber);
%         figure(figNumber);
     
    case 'Selectfile'   
        [FileName,PathName] = uigetfile ('*.mat','Select file');
        FileName = [PathName FileName];
        load (FileName);
        
        h = findobj (gcf,'Tag','InputFile');
        set (h,'String',FileName);

        if exist('Q')
            m = size(Q,1);
        end
        
    case 'compute'
        FileName = get (findobj (gcf,'Tag','InputFile'),'String');
        load (FileName);
        if (~exist('Q'))
            msgbox('Incorrect input file: variance matrix Q not present');
            return;
        end
        if get(findobj(gcf,'Tag','bspec'),'Value') || (~exist('b'))
            bcyc = str2num(get(findobj(gcf,'Tag','bcycles'),'String'));
            m = size(Q,1); b    = bcyc * ones(m,1);
        end
                            
        decor   = get(findobj(gcf,'Tag','decor'),'Value');
        if decor ==2, decor = 0; end
        decorR  = get(findobj(gcf,'Tag','decorR'),'Value');
        if decorR ==2, decorR = 0; end
%         Ps0     = get(findobj(gcf,'Tag','Ps0'),'String');      Ps0   = str2num(Ps0);
        
        
        Qa = Q;  clear Q
        
                   
                %ILS
                method = 1;
                mopt = []; mopt2 = []; Ps = [];  ii = 0;
                nsamp   = get(findobj(gcf,'Tag','nsample'),'String');  nsamp = str2num(nsamp );
                if get (findobj (gcf,'Tag','ILS1'),'Value'); mopt = [mopt 1]; ii=ii+1; string(ii,1:32)=' '; string(ii,1:20)='AP: simulation-based'; end;
                if get (findobj (gcf,'Tag','ILS2'),'Value'); mopt = [mopt 2]; ii=ii+1; string(ii,1:32)=' '; string(ii,1:14)='AP: ADOP-based';      end;
                if get (findobj (gcf,'Tag','ILS3'),'Value'); mopt = [mopt 3]; ii=ii+1; string(ii,1:32)=' '; string(ii,1:17)='LB: bootstrapping';    end;
                if get (findobj (gcf,'Tag','ILS4'),'Value'); mopt = [mopt 4]; ii=ii+1; string(ii,1:32)=' '; string(ii,1:19)='LB: bounding region';  end;
                if get (findobj (gcf,'Tag','ILS5'),'Value'); mopt = [mopt 5]; ii=ii+1; string(ii,1:32)=' '; string(ii,1:22)='LB: bounding vc-matrix';    end;
                if get (findobj (gcf,'Tag','ILS7'),'Value'); mopt = [mopt 6]; ii=ii+1; string(ii,1:32)=' '; string(ii,1:14)='UB: ADOP-based';          end;
                if get (findobj (gcf,'Tag','ILS8'),'Value'); mopt = [mopt 7]; ii=ii+1; string(ii,1:32)=' '; string(ii,1:19)='UB: bounding region';  end;
                if get (findobj (gcf,'Tag','ILS9'),'Value'); mopt = [mopt 8]; ii=ii+1; string(ii,1:32)=' '; string(ii,1:22)='UB: bounding vc-matrix';     end;
                if get (findobj (gcf,'Tag','biasILS1'),'Value'); mopt2 = [mopt2 1]; ii=ii+2; string(ii,1:28)='Bias-affected success rates:'; 
                    ii=ii+1; string(ii,1:32)=' '; string(ii,1:20)='AP: simulation-based'; end;
                if get (findobj (gcf,'Tag','biasILS2'),'Value'); mopt2 = [mopt2 2];  if length(mopt2)==1,  ii=ii+2; string(ii,1:32)=' ';string(ii,1:28)='Bias-affected success rates:';end
                    ii=ii+1; string(ii,1:32)=' '; string(ii,1:2)='LB'; end;
                if get (findobj (gcf,'Tag','biasILS3'),'Value'); mopt2 = [mopt2 3]; if length(mopt2)==1,  ii=ii+2; string(ii,1:32)=' ';string(ii,1:28)='Bias-affected success rates:';end
                    ii=ii+1; string(ii,1:32)=' '; string(ii,1:2)='UB'; end;
                watchon;
                numopt=length(mopt);numopt2=length(mopt2);
                for i = 1:numopt
                    Ps(i) = SuccessRate(Qa, method, mopt(i), 1, nsamp);
                end
                for i = 1:numopt2
                    Ps(i+numopt) = SuccessRateBias(Qa, method, b, mopt2(i), 1, nsamp);
                end
                watchoff;
                for j = 1:numopt
                    if (Ps(j)<0)
                        string(j,26:33) = sprintf ('%6.5f',Ps(j));
                    else
                        string(j,27:33) = sprintf ('%6.5f',Ps(j));
                    end
                end;
                if numopt2>0
                    for j = 1:numopt2
                        if (Ps(j+numopt)<0)
                            string(j+numopt+3,26:33) = sprintf ('%6.5f',Ps(j+numopt));
                        else
                            string(j+numopt+2,27:33) = sprintf ('%6.5f',Ps(j+numopt));
                        end
                    end;
                end
                h = findobj (gcf,'Tag','outputILS');
                if numopt > 0
                    set (h,'String',string);
                else
                    set(h,'String',[])
                end
                
                %bootstrapping
                method = 2;
                mopt = [];  mopt2 = []; Ps = [];  ii = 0;
                if get (findobj (gcf,'Tag','boot1'),'Value'); mopt = [mopt 1]; ii=ii+1; stringB(ii,1:32)=' '; stringB(ii,1:18)='Exact success rate'; end;
                if get (findobj (gcf,'Tag','boot2'),'Value'); mopt = [mopt 2]; ii=ii+1; stringB(ii,1:32)=' '; stringB(ii,1:14)='UB: ADOP-based';      end;
                if get (findobj (gcf,'Tag','biasboot1'),'Value'); mopt2 = [mopt2 1];  ii=ii+2; stringB(ii,1:28)='Bias-affected success rates:'; 
                    ii=ii+1; stringB(ii,1:32)=' '; stringB(ii,1:18)='Exact success rate';  end;
                if get (findobj (gcf,'Tag','biasboot2'),'Value'); mopt2 = [mopt2 2];  if length(mopt2)==1,  ii=ii+2; stringB(ii,1:32)=' ';stringB(ii,1:28)='Bias-affected success rates:';end
                    ii=ii+1; stringB(ii,1:32)=' '; stringB(ii,1:2)='LB';  end;
                if get (findobj (gcf,'Tag','biasboot3'),'Value'); mopt2 = [mopt2 3];  if length(mopt2)==1,  ii=ii+2; stringB(ii,1:32)=' ';stringB(ii,1:28)='Bias-affected success rates:';end
                    ii=ii+1; stringB(ii,1:32)=' '; stringB(ii,1:2)='UB';  end;
                
                watchon;
                numopt=length(mopt);numopt2=length(mopt2);
                if (numopt == 2)
                    Ps = SuccessRate(Qa, method, 3, decor, nsamp);
                else
                    for i = 1:numopt
                        Ps(i) = SuccessRate(Qa, method, mopt(i), decor, nsamp);
                    end
                end

                for i = 1:numopt2
                    Ps(i+numopt) = SuccessRateBias(Qa, method, b, mopt2(i), decor, nsamp);
                end

                watchoff;
                for j = 1:numopt
                    if (Ps(j)<0)
                        stringB(j,26:33) = sprintf ('%6.5f',Ps(j));
                    else
                        stringB(j,27:33) = sprintf ('%6.5f',Ps(j));
                    end
                end;
                if numopt2>0
                    for j = 1:numopt2
                        if (Ps(j)<0)
                            stringB(j+numopt+2,26:33) = sprintf ('%6.5f',Ps(j+numopt));
                        else
                            stringB(j+numopt+2,27:33) = sprintf ('%6.5f',Ps(j+numopt));
                        end
                    end;
                end
                h = findobj (gcf,'Tag','outputB');
                if numopt > 0
                    set (h,'String',stringB);
                else
                    set(h,'String',[])
                end
                
                
                %rounding
                method = 3;
                mopt = []; mopt2 = []; Ps = [];  ii = 0;
                if get (findobj (gcf,'Tag','round1'),'Value'); mopt = [mopt 1]; ii=ii+1; stringR(ii,1:32)=' '; stringR(ii,1:20)='AP: simulation-based'; end;
                if get (findobj (gcf,'Tag','round2'),'Value'); mopt = [mopt 2]; ii=ii+1; stringR(ii,1:32)=' '; stringR(ii,1:2)='LB'; end;
                if get (findobj (gcf,'Tag','round3'),'Value'); mopt = [mopt 3]; ii=ii+1; stringR(ii,1:32)=' '; stringR(ii,1:17)='UB: bootstrapping'; end;
                if get (findobj (gcf,'Tag','biasround1'),'Value'); mopt2 = [mopt2 1]; ii=ii+1; stringR(ii,1:32)=' '; ii=ii+1; stringR(ii,1:28)='Bias-affected success rates:'; 
                    ii=ii+1; stringR(ii,1:32)=' '; stringR(ii,1:20)='AP: simulation-based'; end;
                if get (findobj (gcf,'Tag','biasround2'),'Value'); mopt2 = [mopt2 2];  if length(mopt2)==1, ii=ii+2; stringR(ii,1:32)=' '; stringR(ii,1:28)='Bias-affected success rates:';end
                    ii=ii+1; stringR(ii,1:32)=' '; stringR(ii,1:2)='LB'; end;
                if get (findobj (gcf,'Tag','biasround3'),'Value'); mopt2 = [mopt2 3];if length(mopt2)==1,  ii=ii+2; stringR(ii,1:32)=' '; stringR(ii,1:28)='Bias-affected success rates:';end
                    ii=ii+1; stringR(ii,1:32)=' '; stringR(ii,1:2)='UB'; end;
                
                watchon;
                numopt=length(mopt);numopt2=length(mopt2);
                for i = 1:numopt
                    Ps(i) = SuccessRate(Qa,method,mopt(i),decorR, nsamp);
                end
                for i = 1:numopt2
                    Ps(i+numopt) = SuccessRateBias(Qa, method, b, mopt2(i), decorR, nsamp);
                end
                watchoff;
                for j = 1:numopt
                    if (Ps(j)<0)
                        stringR(j,26:33) = sprintf ('%6.5f',Ps(j));
                    else
                        stringR(j,27:33) = sprintf ('%6.5f',Ps(j));
                    end
                end;
               if numopt2>0
                    for j = 1:numopt2
                        if (Ps(j)<0)
                            stringR(j+numopt+2,26:33) = sprintf ('%6.5f',Ps(j+numopt));
                        else
                            stringR(j+numopt+2,27:33) = sprintf ('%6.5f',Ps(j+numopt));
                        end
                    end;
               end
               h = findobj (gcf,'Tag','outputR');
               if numopt > 0
                   set (h,'String',stringR);
               else
                   set(h,'String',[])
               end

       
    case 'select';
        switch option1
            case 'ILS'
                sel = get(findobj(gcf,'Tag','ILSall'),'Value');
                set(findobj(gcf,'Tag','ILS1'),'Value',sel);
                set(findobj(gcf,'Tag','ILS2'),'Value',sel);
                set(findobj(gcf,'Tag','ILS3'),'Value',sel);
                set(findobj(gcf,'Tag','ILS4'),'Value',sel);
                set(findobj(gcf,'Tag','ILS5'),'Value',sel);
                set(findobj(gcf,'Tag','ILS7'),'Value',sel);
                set(findobj(gcf,'Tag','ILS8'),'Value',sel);
                set(findobj(gcf,'Tag','ILS9'),'Value',sel);                                    
            case 'B'
                sel = get(findobj(gcf,'Tag','Ball'),'Value');
                set(findobj(gcf,'Tag','boot1'),'Value',sel);
                set(findobj(gcf,'Tag','boot2'),'Value',sel);
            case 'R'
                sel = get(findobj(gcf,'Tag','Rall'),'Value');
                set(findobj(gcf,'Tag','round1'),'Value',sel);
                set(findobj(gcf,'Tag','round2'),'Value',sel);
                set(findobj(gcf,'Tag','round3'),'Value',sel);
            case 'ILSbias'
                sel = get(findobj(gcf,'Tag','ILSbiasall'),'Value');
                set(findobj(gcf,'Tag','biasILS1'),'Value',sel);
                set(findobj(gcf,'Tag','biasILS2'),'Value',sel);
                set(findobj(gcf,'Tag','biasILS3'),'Value',sel);                                  
            case 'Bbias'
                sel = get(findobj(gcf,'Tag','Bbiasall'),'Value');
                set(findobj(gcf,'Tag','biasboot1'),'Value',sel);
                set(findobj(gcf,'Tag','biasboot2'),'Value',sel);
                set(findobj(gcf,'Tag','biasboot3'),'Value',sel);
            case 'Rbias'
                sel = get(findobj(gcf,'Tag','Rbiasall'),'Value');
                set(findobj(gcf,'Tag','biasround1'),'Value',sel);
                set(findobj(gcf,'Tag','biasround2'),'Value',sel);
                set(findobj(gcf,'Tag','biasround3'),'Value',sel);
        end
        
    case 'bias';
        
        switch option1
            case 'file'
                set(findobj(gcf,'Tag','bfile'),'Value',1);
                set(findobj(gcf,'Tag','bspec'),'Value',0);  
                set(findobj(gcf,'Tag','bcycles'),'Enable','Off');
            case 'spec'
                set(findobj(gcf,'Tag','bfile'),'Value',0);
                set(findobj(gcf,'Tag','bspec'),'Value',1);
                set(findobj(gcf,'Tag','bcycles'),'Enable','On');
        end        



    case 'default'
        
      
        set(findobj(gcf,'Tag','ILS1'),'Value',0);
        set(findobj(gcf,'Tag','ILS2'),'Value',0);
        set(findobj(gcf,'Tag','ILS3'),'Value',1);
        set(findobj(gcf,'Tag','ILS4'),'Value',0);
        set(findobj(gcf,'Tag','ILS5'),'Value',0);
        set(findobj(gcf,'Tag','ILS7'),'Value',0);
        set(findobj(gcf,'Tag','ILS8'),'Value',0);
        set(findobj(gcf,'Tag','ILS9'),'Value',0);
        set(findobj(gcf,'Tag','decor'),'Value',1);
        set(findobj(gcf,'Tag','boot1'),'Value',1);
        set(findobj(gcf,'Tag','boot2'),'Value',0);
        set(findobj(gcf,'Tag','decorR'),'Value',1);
        set(findobj(gcf,'Tag','round1'),'Value',0);
        set(findobj(gcf,'Tag','round2'),'Value',0);
        set(findobj(gcf,'Tag','round3'),'Value',1);
        set(findobj(gcf,'Tag','biasILS1'),'Value',0);
        set(findobj(gcf,'Tag','biasILS2'),'Value',0);
        set(findobj(gcf,'Tag','biasILS3'),'Value',0);
        set(findobj(gcf,'Tag','biasboot1'),'Value',0);
        set(findobj(gcf,'Tag','biasboot2'),'Value',0);
        set(findobj(gcf,'Tag','biasboot3'),'Value',0);
        set(findobj(gcf,'Tag','biasround1'),'Value',0);
        set(findobj(gcf,'Tag','biasround2'),'Value',0);
        set(findobj(gcf,'Tag','biasround3'),'Value',0);        
 
        set(findobj(gcf,'Tag','ILSall'),'Value',0);  
        set(findobj(gcf,'Tag','Ball'),'Value',0); 
        set(findobj(gcf,'Tag','Rall'),'Value',0); 
        set(findobj(gcf,'Tag','ILSbiasall'),'Value',0);  
        set(findobj(gcf,'Tag','Bbiasall'),'Value',0); 
        set(findobj(gcf,'Tag','Rbiasall'),'Value',0); 
        
        set(findobj(gcf,'Tag','bfile'),'Value',1);
        set(findobj(gcf,'Tag','bspec'),'Value',0);  
        set(findobj(gcf,'Tag','bcycles'),'Enable','Off','String','0.1');
  
         set(findobj(gcf,'Tag','nsample'),'String',100000);

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
%         error('Illegal action, SR_GUI ended');
end

