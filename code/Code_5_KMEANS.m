%Proyecto: Guante_Traductor
%Descripcion: Entrena un KNN a traves de una validacion
%             cruzada, posteriormente hace la predicciones y compara con la 
%             clase real e imprime el error promedio, usa el archivo JOINNEDDATA.mat,
%             puede desplegar la confusionMatrix y Diagrama de Arbol
%  
%Nota: los datos deben estar normalizados
%      aplicar PCA no genera gran diferencia en los resultados
%      el grado de error no es tan consistente
%      se comporta mejor con JOINNEDDATA

close all;                          %Limpiar y cerrar todo 
clear all;
clc;

%%%%%%%%%%%%%%%%%%%%Parametros modificables%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
min_resist = 10000;  %Resistencia minima de la flexo - MODIFICAR de acuerdo a nuevas pruebas!!!
max_resist = 40000;  %Resistencia maxima de la flexo - MODIFICAR de acuerdo a nuevas pruebas!!!
normalizeData = 1;   %Normalizar los datos 1=Si, 0= No
numLetras = 27;      %Numero de letras
numPruebas = 660;     %Numero de Pruebas
numParam = 9;        %Numero de Parametros
plotConfusion = 1;   %Mostrar el Confusion Diagram
applyPCA = 0;        %Aplicar PCA a datos 7in,7out
folds = 2; 
%%%%%%%%%%%%%%%%%%%%Generacion de Datos y Targets%%%%%%%%%%%%%%%%%%%%%%%%%%

load(strcat('TOTALDATA','.mat'));   %Cargar archivos con datos de parametros
Letra = {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}; %Letras analizadas
Confusion = zeros(numLetras,numLetras);             %Matriz para datos de confusion diagram
Confusion2 = zeros(numLetras,numLetras); 

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
    numParam = 5;
    JOINNEDDATA = abs(JOINNEDDATA(:,1:numParam));
end

%%%%%%%%%%%%%%Crossvalidation, Clustering, Prediccion trough KNN%%%%%%%%%%%%%%%%% 

err = 0;  
TARGETS= [];                          %Array para los TARGETS
for a = 1 : numLetras                        
    for b = 1 : numPruebas   
        TARGETS = [TARGETS;  a];
    end
end

CVO = cvpartition(TARGETS,'k',folds);   %Objeto CV

for b = 1 : 1%CVO.NumTestSets             %Por cada fold
    
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
    
    trIdx = [1:size(JOINNEDDATA,1)]; 
    teIdx = [1:size(JOINNEDDATA,1)]; 
    
    [idx,ctrs] = kmeans(JOINNEDDATA(trIdx,:), numLetras,'Distance','cosine',...
              'Replicates',3);
          
    ytest = knnclassify(JOINNEDDATA(teIdx,:), ctrs, (1:27), 1, 'euclidean','nearest');
  
          
    for o = 1 : length(ytest)                           %Para todo el conjunto de predicted labels
            Confusion(ytest(o),TARGETS(teIdx(o))) = Confusion(ytest(o),TARGETS(teIdx(o)))+1;          %Incrementa en una unidad la posicion m,n;                                                        % donde m=predictedLabel, n=realLabel       
    end
    
%     figure
%     imagesc(Confusion), colorbar
%     ylabel('Letras')
%     xlabel('Cluster')
%     set(gca, 'YTick', [1:1:numLetras], 'YTickLabel', {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','Ñ','O','P','R','S','T','U','V','W','X','Y','Z'});

    for c = 1 : numLetras
        [m,n] = max(Confusion(c,:));
        Confusion2(n,:) = Confusion2(n,:)+Confusion(c,:);
    end

end

figure
imagesc(Confusion), colorbar
ylabel('Prediccion')
xlabel('Real')
set(gca, 'YTick', [1:1:numLetras], 'YTickLabel', {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','Ñ','O','P','R','S','T','U','V','W','X','Y','Z'});
set(gca, 'XTick', [1:1:numLetras], 'XTickLabel', {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','Ñ','O','P','R','S','T','U','V','W','X','Y','Z'});

figure
imagesc(Confusion2), colorbar
ylabel('Prediccion')
xlabel('Real')
set(gca, 'YTick', [1:1:numLetras], 'YTickLabel', {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','Ñ','O','P','R','S','T','U','V','W','X','Y','Z'});
set(gca, 'XTick', [1:1:numLetras], 'XTickLabel', {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','Ñ','O','P','R','S','T','U','V','W','X','Y','Z'});

%for a=1:27
%    err = err + abs(floor(CVO.TestSize(1)/numLetras)-Confusion2(a,a));
%end
%err = err / sum(CVO.TestSize)

for a=1:27
    err = err + abs(floor(size(JOINNEDDATA,1)/numLetras)-Confusion2(a,a));
end
err = err / size(JOINNEDDATA,1)