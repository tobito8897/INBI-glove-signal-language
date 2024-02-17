%Proyecto: Guante_Traductor
%Descripcion: Entrena arboles de desiciones a traves de una validacion
%             cruzada, posteriormente hace la predicciones y compara con la 
%             clase real e imprime el error promedio, usa el archivo JOINNEDDATA.mat,
%             puede desplegar la confusionMatrix y Diagrama de Arbol
%             
%Nota: no afecta si los datos estan normalizados o no.
%      aplicar PCA genera un gran crecimiento en el error   
%      se comporta mejor con TOTALDATA.mat

close all;                          %Limpiar y cerrar todo 
clear all;
clc;

%%%%%%%%%%%%%%%%%%%%Parametros modificables%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
min_resist = 10000;  %Resistencia minima de la flexo - MODIFICAR de acuerdo a nuevas pruebas!!!
max_resist = 40000;  %Resistencia maxima de la flexo - MODIFICAR de acuerdo a nuevas pruebas!!!
normalizeData = 0;   %Normalizar los datos 1=Si, 0= No
folds = 2;           %Folds de la k-fold validation
numLetras = 27;      %Numero de letras
numPruebas = 660;    %Numero de Pruebas
numParam = 9;        %Numero de Parametros
plotTree = 1;        %Mostrar el arbol de desicion
plotConfusion = 1;   %Mostrar el Confusion Diagram
plotExtraGraphs = 0; %Mostrar graficas Auxiliares
applyPCA = 0;        %Aplicar PCA a datos

%%%%%%%%%%%%%%%%%%%%Generacion de Datos y Targets%%%%%%%%%%%%%%%%%%%%%%%%%%

load(strcat('TOTALDATA','.mat'));   %Cargar archivos con datos de parametros
Letra = {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}; %Letras analizadas
Confusion = zeros(numLetras,numLetras);             %Matriz para datos de confusion diagram

if normalizeData   %Normalizacion de datos, el .mat los tiene normalizados
    JOINNEDDATA(:,1:5) = (JOINNEDDATA(:,1:5)-min_resist)/(max_resist-min_resist);
end

if applyPCA         %Aplicar PCA
    for a=1 : numParam
        for b=1 : numParam
           c = corrcoef(JOINNEDDATA(a,:),JOINNEDDATA(b,:)); %Generacion de matriz de corrcoef
           D(a,b) = c(2);
        end
    end
    [V,D] = eig(D); %Obtencion de eigenvectores
    JOINNEDDATA = JOINNEDDATA*V; %Multiplicacion de Datos por matriz de eigenvectores
    numParam = 9;
    JOINNEDDATA = abs(JOINNEDDATA(:,1:numParam));
end

TARGETS= [];                          %Array para los TARGETS
for a = 1 : numLetras                        
    for b = 1 : numPruebas   
        TARGETS = [TARGETS;  Letra(a)];
    end
end

%%%%%%%%%%%%%%Crossvalidation, treefitting, treeprediction%%%%%%%%%%%%%%%%% 

CVO = cvpartition(TARGETS,'k',folds);   %Objeto CV
err = zeros(CVO.NumTestSets,1);         %Numero de pruebas = folds
for b = 1 : CVO.NumTestSets             %Por cada fold
    
    Idx = CVO.training(b);              %Indices de muestras que se usaran para training 
    trIdx = [];  
    for a = 1 : numLetras*numPruebas
        if Idx(a) 
            trIdx = [trIdx a];
        end
    end
    
    Idx = CVO.test(b);                 %Indices de muestras que se usaron para testing
    teIdx = [];  
    for a = 1 : numLetras*numPruebas
        if Idx(a)
            teIdx = [teIdx a];
        end
    end
    
    trIdx = int16(trIdx);                                        %Conversion de indices a enteros
    teIdx = int16(teIdx);
    TREEmodel = treefit(JOINNEDDATA(trIdx,:),TARGETS(trIdx));    %Entrenamiento del arbol con el trainData
    ytest = treeval(TREEmodel,JOINNEDDATA(teIdx,:));             %Prediccion con el testData 
    ytest = TREEmodel.classname(ytest);                          %Predicted labels se cambian de numeros a su string correspondiente                         
    err(b) = sum(~strcmp(ytest,TARGETS(teIdx)));                 %Numero de errores de prediccion, ValorReal vs ValorPredecido
    
    %Generacion de confusion diagram
    for o = 1 : length(ytest)                           %Para todo el conjunto de predicted labels
            for m = 1 : numLetras
                 if strcmp(Letra{m}, ytest{o})          %Determina la letra que fue predecida
                     break
                 end
            end
            for n = 1 : numLetras              
                 if strcmp(Letra{n}, TARGETS(teIdx(o))) %Determina la letra que en realidad fue hecha  
                     break
                 end
            end
            Confusion(m,n) = Confusion(m,n)+1;          %Incrementa en una unidad la posicion m,n; 
                                                        % donde m=predictedLabel, n=realLabel       
    end
end
cvErr = sum(err)/sum(CVO.TestSize)                      %Error Promedio

%%%%%%%%%%%%%%%%%%%%%%%%%%%%Graficas y eso...%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if plotTree        %Mostrar el arbol de desicion
    treedisp(TREEmodel,'names',{'F1' 'F2' 'F3' 'F4' 'F5' 'T1' 'T2','M','D'});   %Ploteo del ultimo arbol entrenado
end

if plotConfusion    %Mostrar diagrama de confusions
    figure
    imagesc(Confusion), colorbar
    ylabel('Prediccion')
    xlabel('Real')
    set(gca, 'YTick', [1:1:numLetras], 'YTickLabel', {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','Ñ','O','P','R','S','T','U','V','W','X','Y','Z'});
    set(gca, 'XTick', [1:1:numLetras], 'XTickLabel', {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','Ñ','O','P','R','S','T','U','V','W','X','Y','Z'});
end

if plotExtraGraphs

    %%%%%%%%%%%%%%%Graficas de los parametros solo para visualizacion%%%%%%%%%%
    %Nota: Solo se grafican 7 letras xq el vector de colores solo tiene 7
    %      colores

    color = [1 1 0; 1 0 1; 0 1 1; 1 0 0; 0 1 0; 0 0 1; 0 0 0];
    q=1;
    for e = 11 : 14 %Letras a plotear - Flex1
        scatter(JOINNEDDATA((e-1)*numPruebas+1:e*numPruebas,1),ones(numPruebas,1),'MarkerEdgeColor', color(q,:))
        hold on
        q=q+1;
    end
    q=1;
    for e = 11 : 14 %Letras a plotear - Flex2
        scatter(JOINNEDDATA((e-1)*numPruebas+1:e*numPruebas,2),2*ones(numPruebas,1),'MarkerEdgeColor', color(q,:))
        hold on
        q=q+1;
    end
    q=1;
    for e = 11 : 14 %Letras a plotear - Flex3
        scatter(JOINNEDDATA((e-1)*numPruebas+1:e*numPruebas,3),3*ones(numPruebas,1),'MarkerEdgeColor', color(q,:))
        hold on
        q=q+1;
    end
    q=1;
    for e = 11 : 14 %Letras a plotear - Flex4
        scatter(JOINNEDDATA((e-1)*numPruebas+1:e*numPruebas,4),4*ones(numPruebas,1),'MarkerEdgeColor', color(q,:))
        hold on
        q=q+1;
    end
    q=1;
    for e = 11 : 14 %Letras a plotear - Flex5
        scatter(JOINNEDDATA((e-1)*numPruebas+1:e*numPruebas,5),5*ones(numPruebas,1),'MarkerEdgeColor', color(q,:))
        hold on
        q=q+1;
    end
    q=1;

    if normalizeData
        for e = 11 : 14 %Letras a plotear - T1
            scatter(JOINNEDDATA((e-1)*numPruebas+1:e*numPruebas,6),6*ones(numPruebas,1),'MarkerEdgeColor', color(q,:))
            hold on
            xlim([0 1])
            q=q+1;
        end
        q=1;
        for e = 11 : 14 %Letras a plotear - T2
            scatter(JOINNEDDATA((e-1)*numPruebas+1:e*numPruebas,7),7*ones(numPruebas,1),'MarkerEdgeColor', color(q,:))
            hold on
            xlim([0 1])
            q=q+1;
        end
        for e = 11 : 14 %Letras a plotear - A1
            scatter(JOINNEDDATA((e-1)*numPruebas+1:e*numPruebas,8),8*ones(numPruebas,1),'MarkerEdgeColor', color(q,:))
            hold on
            xlim([0 1])
            q=q+1;
        end
    end

end