%Proyecto: Guante_Traductor
%Descripcion: Genera un SVM multiclass, usando el ONE VS ALL, y realiza una
%             cross validation, con ello calcula el error. Puede desplegar 
%             la confusionMatrix y un Boundaries Diagrama de 2D
%Nota: La SVM por default normaliza los datos
%      no se pudo probar con TOTALDATA xq tarda mucho
%      aplicar PCA empeora los resultados bastante

close all;                            %Limpiar y cerrar todo 
clear all;
clc;

%%%%%%%%%%%%%%%%%%%%Parametros modificables%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
min_resist = 10000;           %Resistencia minima de la flexo - MODIFICAR de acuerdo a nuevas pruebas!!!
max_resist = 40000;           %Resistencia maxima de la flexo - MODIFICAR de acuerdo a nuevas pruebas!!!
folds = 5;                    %Folds 
numLetras = 27;               %Numero de Letras
numPruebas = 10;              %Numero de Pruebas
numParam = 9;                 %Numero de Parametros
applyPCA = 0;                 %Aplicar PCA a datos? - 7in 7out
normalizeData = 0;            %Normalizar datos?
plotConfusion = 1;            %Desplegar confusionMatrix
plotDesitionBound = 0;        %Desplegar un diagrama de los limites de desicion (grafico en 2d)...
                              %para ello se varian solo 2 parametros, los
                              %demas se mantienen fijos
desiAxis1 = 1;                %Parametros que se variaran 
desiAxis2 = 5;
desiValues = [0 30000 35000 35000 30000 1 0 0 2];     %Valores para parametros fijos
                                            %Tener cuidado si se normalizaran los datos  

load(strcat('JOINNEDDATA','.mat'));   %Cargar archivos con datos de parametros
Letra = {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}; %Letras
Param = {'F1' 'F2' 'F3' 'F4' 'F5' 'T1' 'T2','M','D'};
Confusion = zeros(numLetras,numLetras);             %Matriz para datos de confusion matrix

if normalizeData            %Desnormalizacion de datos, el .mat los tiene normalizados
    JOINNEDDATA(:,1:5) = (JOINNEDDATA(:,1:5)-min_resist)/(max_resist-min_resist);
end

if applyPCA                          %Aplicar PCA
    for a= 1 : numParam
        for b=1 : numParam
           c = corrcoef(JOINNEDDATA(a,:),JOINNEDDATA(b,:)); %Generacion de matriz de corrcoef
           D(a,b) = c(2);
        end
    end
    [V,D] = eig(D);                  %Obtencion de eigenvectores
    JOINNEDDATA = JOINNEDDATA*V;     %Multiplicacion de Datos por matriz de eigenvectores
    numParam = 9;
    JOINNEDDATA = abs(JOINNEDDATA(:,1:numParam));
end

TARGETS= [];                         %Array para los TARGETS
for a = 1 : numLetras                        
    for b = 1 : numPruebas  
        TARGETS = [TARGETS;  Letra(a)];
    end
end

CVO = cvpartition(TARGETS','k',folds);%Objeto CV
err = zeros(CVO.NumTestSets,1);       %NumTestSets = folds

for t = 1:CVO.NumTestSets             %Por cada fold 
    
    Idx = CVO.training(t);            %Indices de muestras que se usaran para training 
    trIdx = [];  
    for a = 1 : numLetras*numPruebas
        if Idx(a) 
            trIdx = [trIdx a];
        end
    end
    
    Idx = CVO.test(t);                %Indices de muestras que se usaron para testing
    teIdx = [];  
    for a=1 : numLetras*numPruebas
        if Idx(a)
            teIdx = [teIdx a];
        end
    end

    numClasses=length(Letra);         %Numero de clases 
    result = zeros(length(JOINNEDDATA(teIdx,:)),1); 

    %Construye un Modelo para clasificar cada Letra (numClasses) con la tecnica ONEvsALL
    %y los almacena en una estructura
    for k=1:numClasses
        G1vAll=strcmp(TARGETS(trIdx,1), Letra(k)); %Genera un vector de TARGETS donde todas las clases salvo la u(k) 
                                                   %se ponen en zeros (ONEvsALL)
        SVMmodels(k) = svmtrain(JOINNEDDATA(trIdx,:),G1vAll,'kernel_function','polynomial','polyorder',3);%Modelo para identificar
                                               %la clase u(k)
    end
    
    %Para cada observacion del testSet prueba todos los modelos, hasta que
    %uno genera una clasificacion positiva ('parte de la clase de ese Modelo')
    for j=1:size(JOINNEDDATA(teIdx,:),1)
        for k=1:numClasses
            if(svmclassify(SVMmodels(k),JOINNEDDATA(teIdx(j),:))) 
                break;
            end
        end
        result(j) = k;                            %Guarda las predicciones de forma numerica
    end

    for k=1:length(result)                        %Traduce los classNumber en su respectiva classLabel
        labels(k) = Letra(result(k));
    end
    err(t) = sum(~strcmp(labels',TARGETS(teIdx)));%Compara predictedClass vs realClass
    
    %Generacion de matriz de Confusion
    for o = 1 : length(labels)                           %Para todo el conjunto de predicted labels
            for m = 1 : numLetras
                 if strcmp(Letra{m}, labels{o})          %Determina la letra que fue predecida
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
    
cvErr = sum(err)/sum(CVO.TestSize) %Promedio del error

if plotConfusion                   %Mostrar matriz de Confusion
    imagesc(Confusion), colorbar
    ylabel('Prediccion')
    xlabel('Real')
    set(gca, 'YTick', [1:1:numLetras], 'YTickLabel', {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'});
    set(gca, 'XTick', [1:1:numLetras], 'XTickLabel', {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'});
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
        for k=1:numClasses
            if(svmclassify(SVMmodels(k),Simulation(j,:))) 
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
