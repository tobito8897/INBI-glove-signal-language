%Proyecto: Guante_Traductor
%Descripcion: Entrena un KNN a traves de una validacion
%             cruzada, posteriormente hace la predicciones y compara con la 
%             clase real e imprime el error promedio, usa el archivo JOINNEDDATA.mat,
%             puede desplegar la confusionMatrix y Diagrama de Arbol
%  
%Nota: los datos deben estar normalizados
%      aplicar PCA no genera diferencia en los resultados      
%      comportamiento similar entre JOINNEDDATA Y TOTALDATA

close all;                          %Limpiar y cerrar todo 
clear all;
clc;

%%%%%%%%%%%%%%%%%%%%Parametros modificables%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
min_resist = 10000;  %Resistencia minima de la flexo - MODIFICAR de acuerdo a nuevas pruebas!!!
max_resist = 40000;  %Resistencia maxima de la flexo - MODIFICAR de acuerdo a nuevas pruebas!!!
normalizeData = 1;   %Normalizar los datos 1=Si, 0= No
folds = 2;           %Folds de la k-fold validation
numLetras = 27;      %Numero de letras
numPruebas = 660;     %Numero de Pruebas
numParam = 9;        %Numero de Parametros
plotTree = 1;        %Mostrar el arbol de desicion
plotConfusion = 1;   %Mostrar el Confusion Diagram
applyPCA = 0;        %Aplicar PCA a datos 7in,7out
plotDesitionBound = 0;        %Desplegar un diagrama de los limites de desicion (grafico en 2d)...
                              %para ello se varian solo 2 parametros, los
                              %demas se mantienen fijos
desiAxis1 = 1;                %Parametros que se variaran 
desiAxis2 = 5;
desiValues = [0 30000 35000 35000 30000 1 0 0 2];     %Valores para parametros fijos
                                            %Tener cuidado si se normalizaran los datos  
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
        TARGETS = [TARGETS;  a];
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
    
    ytest = knnclassify(JOINNEDDATA(teIdx,:), JOINNEDDATA(trIdx,:), TARGETS(trIdx), 4, 'cityblock','nearest');
            
    for p = 1 : length(teIdx)
        if ytest(p) ~= TARGETS(teIdx(p))                 %Numero de errores de prediccion, ValorReal vs ValorPredecido
            err(b) = err(b)+1; 
        end
    end
    
    %Generacion de confusion diagram
    for o = 1 : length(ytest)                           %Para todo el conjunto de predicted labels
            Confusion(ytest(o),TARGETS(teIdx(o))) = Confusion(ytest(o),TARGETS(teIdx(o)))+1;          %Incrementa en una unidad la posicion m,n;                                                        % donde m=predictedLabel, n=realLabel       
    end
end
cvErr = sum(err)/sum(CVO.TestSize)                      %Error Promedio

%%%%%%%%%%%%%%%%%%%%%%%%%%%%Graficas y eso...%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if plotConfusion    %Mostrar diagrama de confusions
    figure
    imagesc(Confusion), colorbar
    ylabel('Prediccion')
    xlabel('Real')
    set(gca, 'YTick', [1:1:numLetras], 'YTickLabel', {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','Ñ','O','P','R','S','T','U','V','W','X','Y','Z'});
    set(gca, 'XTick', [1:1:numLetras], 'XTickLabel', {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','Ñ','O','P','R','S','T','U','V','W','X','Y','Z'});
end


if plotDesitionBound                   %Grafico de limites de desicion variando solo 2 parametros
                                       %solo se ejecuta si se normalizan los datos
    y = [0 : 1000 : 40000];                %Valores para parametros que se variaran
    x = [0 : 1000 : 40000];
    Simulation = zeros(length(y)^2,numParam); %51*51 = 2601, observaciones simuladas
    [z1, z2] = meshgrid(y,x);               %Meshgrid 
    z1 = reshape(z1,1,41*41);               %Convierte las matrices a columnas 
    z2 = reshape(z2,1,41*41);
    for t=1 : numParam
        Simulation(:,t) = desiValues(t); %Se ingresan los valores configurados para parametros invariables
    end
    Simulation(:,desiAxis1) = z1;%Se ingresan los valores para parametros que variaran
    Simulation(:,desiAxis2) = z2;
    result=0;
    for j=1:length(Simulation)   %Prediccion con el modelo entrenado previamente con las observaciones simuladas
        k = knnclassify(Simulation(j,:), JOINNEDDATA, TARGETS, 1, 'cosine','random');
        result(j) = k;     
        disp(j);
    end
       
    size1 = 60*ones(1,length(result));    %Tamaños para scatter
    color2 = 0.01*ones(1,length(result)); %Color que tendra cada punto de acuerdo al TARGET que fue predicho
    color = linspace(1,100,numLetras);    %Se genera un color para cada letra
    for u=1 : length(result)              %Por cada observacion 
       for t = 1 : numLetras              %Por cada Letra  
           if result(u) == t              %Si el resultado predicho para una observacion es igual a la letra t
               color2(u) = color(t);      %se le asigna el color(t), notar que es un color diferente dependiendo de la letra
           end
       end
    end    
    
    %Grafica-Las coordenadas de cada punto son los valores de los
    %parametros que se variaron, notar que el chiste del diagrama esta en
    %el vector de colores!
    scatter(Simulation(:,desiAxis1),Simulation(:,desiAxis2),size1,color2,'fill','s');
    hold on;
    ylabel(Param{desiAxis2});
    xlabel(Param{desiAxis1});
    %Para generar la legend
    u = unique(result);
    for q=1 : length(u) %Por cada resultado unico
        text(1.1*40000,q*40000/length(u),Letra{u(q)}) %Se imprime la letra 
        scatter(1.05*40000,q*40000/length(u),40,color(u(q)),'fill') %Y el color que le corresponde a la letra u(q) 
        hold on
    end
    
end
