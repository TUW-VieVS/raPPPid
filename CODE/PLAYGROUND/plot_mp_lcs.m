hsv_color = hsv(32);
loop = 1:5;
prns = [];

for i = loop
    if(any(~isnan(storeData.mp1(:,i))))
        prns = [prns; i];
    end    
end
prns = num2str(prns);


%% PLOT OF mp1-LC
figure
hold on
for i = loop
    data = storeData.mp1(:,i);
    plot(data, 'color', hsv_color(i,:))
    title('mp1-LC')
    legend(prns)
end

%% PLOT OF mp2-LC
% figure
% hold on 
% for i = loop
%     data = storeData.mp2(:,i);
%     plot(data, 'color', hsv_color(i,:))
%     title('mp2-LC')
%     legend(prns)
% end

%% PLOT OF 3-Frequency-Code-LC
% figure
% hold on
% for i = loop
%     data = storeData.MP_c(:,i);
% %     data = data - median(data);
%     plot(data, 'color', hsv_color(i,:))
%     title('3-frq-MP-LC-Code')
%     hold on
% end

%% PLOT OF 3-Frequency-Phase-LC
% figure
% hold on
% for i = loop
%     data = storeData.MP_p(:,i);
% %     data = data - median(data);
%     plot(data, 'color', hsv_color(i,:))
%     title('3-frq-MP-LC-Phase')
%     hold on
% end

%% PLOT OF SATELLITE ELEVATION
% figure
% hold on
% for i = loop
%     data = satellites.elev(:,i);
%     plot(data, 'color', hsv_color(i,:))
%     title('Elevation')
% end


%% PLOT VARIANCE of mp1
figure
hold on
data = storeData.mp1(:,1);
variance_1 = NaN(length(data), numel(loop));
for i = loop
    data = storeData.mp1(:,i);
    if any(~isnan(data))
        for v = 1:5
            variance_1(v,i) = var(data(1:v));
        end
        for v = 6:length(data)
            variance_1(v,i) = var(data(v-5:v));
        end
        
        plot(variance_1(:,i).^-1, 'color', hsv_color(i,:))
    end
end
title('variance mp1-LC, 5 epochs')
legend(prns)

%% PLOT VARIANCE of mp2
% figure
% hold on
% variance_2 = NaN(length(data), numel(loop));
% for i = loop
%     data = storeData.mp2(:,i);
%     for v = 1:5
%         variance_2(v,i) = var(data(1:v));
%     end
%     for v = 6:length(data)
%         variance_2(v,i) = var(data(v-5:v));
%     end
% %     el = satellites.elev(:,i);
%     plot(variance_2(:,i), 'color', hsv_color(i,:))
% end
% title('variance mp2-LC, 5 epochs')  


%% PLOT WEIGHTING WITH MP-LC
figure
hold on
for i = loop
    el = satellites.elev(:,i)*pi/180;       % from [°] in [rad]
    w1 = 1/storeData.mp1(:,i);
    weigth = tanh((variance_1(:,i).^-1)/100) + sin(el);
    plot(weigth, 'color', hsv_color(i,:))
end
title('MP-LC Weighting')




%% PLOT OLD WEIGHTING WITH ELEVATION
figure
hold on
for i = loop
    el = satellites.elev(:,i);
    el = sin(el*pi/180);
    plot(1:numel(el), el, 'color', hsv_color(i,:))
   
end
title('Elevation Weighting')