%Proyecto: Guante_Traductor
%Descripcion: De acuerdo al segmento seleccionado de la señal calcula el
%             promedio y desviacion estandar de todas las pruebas de una letra en ese
%             segmento y grafica el errorbar.

close all;    %Limpiar y cerrar todo
clear all;
clc;

%Vectores que se usan para generar los nombres de los archivos
Letra = {'Rest_','A_','B_','C_','D_','E_','F_','G_','H_','I_','J_','K_','L_','M_','N_','O_','P_','Q_','R_','S_','T_','U_','V_','W_','X_','Y_','Z_'};
Prueba = {'p1','p1','p3','p4','p5','p6','p7','p8','p9','p10'};
Dedos = {' Pulgar',' Indice',' Medio',' Anular',' Meñique','Touch1','Touch2','Movimiento','Direccion'};
Unidades = {'Resistencia(ohms)','Resistencia(ohms)','Resistencia(ohms)','Resistencia(ohms)','Resistencia(ohms)',' ',' ',' ',' ',};

%%%%%%%%%%%%%%%%%%%%%%%%%%%PARAMETROS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
analizeBegin = 80;            %A partir de este punto se toman las muestras
analizeEnd = 140;              %Hasta este punto se toman las muestras
numLetras = 27;                %Numero de letras
numPruebas = 10;               %Numero de Pruebas
numParam = 9;                  %Numero de Parametros

lastingAnalize = analizeEnd - analizeBegin;
DATA = zeros (numParam,(lastingAnalize)*numPruebas );  %Matriz para almacenar datos de las 10 pruebas x letra
DATA_ERRORBAR = zeros (numLetras,numParam,2);          %Matriz para guardar mean y std de todas las letras (21letras x 7par�metros x 2(mean y std))
x_series = [1:1:numLetras];                            %Vector auxiliar para el errobar


for a = 1 : numLetras                                  %28 letras
    for b = 1 : numPruebas                             %10 pruebas por letras
        Nombre_Archivo = strcat(Letra(a), Prueba(b));  %Generacion del nombre de archivo 
        Nombre_Archivo = Nombre_Archivo{1};
        load(strcat(Nombre_Archivo,'.mat'));                  %Cargar datos del archivo en una variable
        DATA(:,((b*lastingAnalize)-(lastingAnalize-1)):(b*lastingAnalize)) = MetaData(1:numParam, analizeBegin :(analizeEnd-1));  %Solo se pasa la se�al en el segmento de tiempo elegido
    end
    
    for z=1:numParam                             %8 parametros 
        DATA_ERRORBAR(a,z,1) = mean(DATA(z,:)) ; %Calculo del promedio
        DATA_ERRORBAR(a,z,2) = std(DATA(z,:)) ;  %Calculo de la desviacion estandar
    end
 
end

%%%%%%%%%%%%%%%%%%%%%%%%%GRAFICAS DEL ERRORBAR%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for v=1 : numParam

figure(v)
errorbar(x_series,DATA_ERRORBAR(:,v,1)',DATA_ERRORBAR(:,v,2)','o');
title(Dedos{v},'FontWeight','bold')
ylabel(Unidades{v})
xlabel('Letra')
set(gca, 'XTick', [1:1:numLetras], 'XTickLabel', {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'});

end

figure(numParam+1)
title('Promedios')
imagesc(DATA_ERRORBAR(:,:,1)), caxis([0 40000]), colorbar
set(gca, 'YTick', [1:1:numLetras], 'YTickLabel', {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'});
set(gca, 'XTick', [1:1:numParam], 'XTickLabel', {'f1','f2','f3','f4','f5','t1','t2','m','d'})

figure(numParam+2)
title('Desviaciones estandar')
imagesc(DATA_ERRORBAR(:,:,2)), caxis([0 40000]), colorbar
set(gca, 'YTick', [1:1:numLetras], 'YTickLabel', {'Rest','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'});
set(gca, 'XTick', [1:1:numParam], 'XTickLabel', {'f1','f2','f3','f4','f5','t1','t2','m','d'})