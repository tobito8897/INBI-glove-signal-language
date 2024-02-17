%Proyecto: Guante_Traductor
%Descripcion: Entrena una red neuronal para clasificar las letras, 
%             usa el archivo JOINNEDDATA.mat, calcula el error aparte
%             segmentando los datos en un conjunto de entrenamiento y
%             testing. Tener en
%             cuenta que el train de la red ya conlleva validacion por lo
%             que podria eliminarse. Se puede desplegar la matrixConfusion,
%             y la red neuronal.
%Nota: aplicar PCA incrementa bastante el error
%      normalizar datos no genera cambios
%      se comporta mejor con TOTALDATA        

close all;                            %Limpiar y cerrar todo 
clear all;
clc;

load(strcat('TOTALDATA','.mat'));   %Cargar archivos con datos de parametros
Letra = {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}; %Letras
Param = {'F1','F2','F3','F4','F5','T1','T2','M','D'}; 

%%%%%%%%%%%%%%%%%%Parametros configurables%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
max_resist = 40000;           %Resistencia minima - Modificar de acuerdo a nuevas pruebas!!!
min_resist = 10000;           %Resistencia maxima - Modificar de acuerdo a nuevas pruebas!!!
folds = 2;                   %Folds 
numLetras = 27;               %Numero de Letras
numPruebas = 660;              %Numero de Pruebas
numParam = 9;                 %Numero de Parametros
numNeuron = 15;
applyPCA = 0;                 %Aplicar PCA a datos? - 7in 7out
normalizeData = 0;            %Normalizar datos?
plotNetwork = 0; 
plotConf = 1;                 %Matriz de confusion
err = 0;                      %Vector de errores
Confusion = zeros(numLetras,numLetras);
ytestAcu = [];
TargetAcu = [];
plotDesitionBound = 0;        %Desplegar un diagrama de los limites de desicion (grafico en 2d)...
                              %para ello se varian solo 2 parametros, los
                              %demas se mantienen fijos
desiAxis1 = 1;                %Parametros que se variaran 
desiAxis2 = 5;
desiValues = [0 25000 30000 30000 25000 1 0 0 2]; %Valores para parametros fijos
                                                  %Tener cuidado si se normalizaran los datos  
LetraNeur = eye(numLetras);

if normalizeData            %Desnormalizacion de datos, el .mat los tiene normalizados
    JOINNEDDATA(:,1:5) = (JOINNEDDATA(:,1:5)-min_resist)/(max_resist-min_resist);
end

if applyPCA                   %Aplicar PCA
    for a= 1 : numParam
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

JOINNEDDATA = JOINNEDDATA';            %OJO: el formato de datos de entrada es diferente para la red
                                       %en comparacion con SVM y TREE

TARGETS1= zeros(numLetras,numLetras*numPruebas);            %Array para los TARGETS
for a = 1 : numLetras                        
      TARGETS1 (a, (a-1)*numPruebas+1 : a*numPruebas) = 1;
end

TARGETS= [];                           %Array para los TARGETS de strings, se usa para la validacion cruzada
for a = 1 : numLetras                        
    for b = 1 : numPruebas   
        TARGETS = [TARGETS;  Letra(a)];
    end
end

CVO = cvpartition(TARGETS','k',folds); %Objeto CV
error = zeros(1,folds);

for s=1: folds
    close all

    Idx = CVO.training(s);                 %Indices de muestras que se usaran para training 
    trIdx = [];  
    for a = 1 : numLetras*numPruebas
        if Idx(a) 
            trIdx = [trIdx a];
        end
    end

    Idx = CVO.test(s);                    %Indices de muestras que se usaron para testing
    teIdx = [];  
    for a=1 : numLetras*numPruebas
        if Idx(a)
            teIdx = [teIdx a];
        end
    end

    setdemorandstream(391418381)         
    REDNEU = patternnet([numNeuron]);              %Creacion de la red.  
    [REDNEU,TRAINDATA] = train(REDNEU,JOINNEDDATA(:,trIdx),TARGETS1(:,trIdx)); %Entrenamiento de la red con los datos del testing

    ytest = round(REDNEU(JOINNEDDATA(:,teIdx)));   %Prediccion con el testData 
                              
    ytestAcu = [ytestAcu ytest];                   %ytest obtenidos de la CV acumulados                  
    TargetAcu = [TargetAcu TARGETS1(:,teIdx)];     %Targets usados en la CV acumulados
end

for o = 1 : size(ytestAcu,2)                      %Para todo el conjunto de predicted labels
    for m = 1 : numLetras
        if isequal(ytestAcu(:,o), LetraNeur(:,m))          %Determina la letra que fue predecida
            break
        end
    end
	for n = 1 : numLetras              
        if isequal(TargetAcu(:,o), LetraNeur(:,n)) %Determina la letra que en realidad fue hecha  
            break
        end
    end
    Confusion(m,n) = Confusion(m,n)+1; 
    if m~=n
        err = err+1;
    end
end

cvErr = err/sum(CVO.TestSize) %Promedio del error

if plotConf                                    %Confusion Matrix Acumulada
    imagesc(Confusion), colorbar
    ylabel('Prediccion')
    xlabel('Real')
    set(gca, 'YTick', [1:1:numLetras], 'YTickLabel', {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'});
    set(gca, 'XTick', [1:1:numLetras], 'XTickLabel', {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'});
end

if plotDesitionBound                   %Grafico de limites de desicion variando solo 2 parametros
                                       %solo se ejecuta si se normalizan los datos
    y = [0 : 1000 : 40000];            %Valores para parametros que se variaran
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
    Simulation = Simulation';
    result=0;
    for j=1:size(Simulation,2)   %Prediccion con el modelo entrenado previamente con las observaciones simuladas
        ytest = round(REDNEU(Simulation(:,j)));
        for k = 1 : numLetras
            if isequal(ytest,LetraNeur(:,k)) 
                break;
            end
        end
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
    scatter(Simulation(desiAxis1,:),Simulation(desiAxis2,:),size1,color2,'fill','s');
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

