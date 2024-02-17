%Proyecto: Guante_Traductor
%Descripcion: Une en una sola matriz los datos de todas las señales de
%             todas las señales, para ello calcula el promedio de cada una (y para cada
%             parametro) del segmento elegido de acuerdo a analizeBegin y
%             analizeEnd. Los datos NO se normalizan


%Vectores que se usan para generar los nombres de los archivos
Letra = {'Rest_','A_','B_','C_','D_','E_','F_','G_','H_','I_','J_','K_','L_','M_','N_','O_','P_','Q_','R_','S_','T_','U_','V_','W_','X_','Y_','Z_'};
Prueba = {'p1','p1','p3','p4','p5','p6','p7','p8','p9','p10'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%PARAMETROS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
analizeBegin = 80;    %Punto inicial para promediar
analizeEnd = 140;      %Punto final para promediar
numLetras = 27;        %Numero de letras
numPruebas = 10;       %Numero de Pruebas
numParam = 9;          %Numero de Parametros

JOINNEDDATA = zeros(numLetras*numPruebas , numParam);   %Matriz de union (Num Letras * Num de Pruebas x Num de Parametros)
lastingAnalize = analizeEnd-analizeBegin;            

for a = 1 : numLetras                        %28 letras
    for b = 1 : numPruebas                   %10 pruebas por letra
        Nombre_Archivo = strcat(Letra(a), Prueba(b));         %Generacion del nombre de archivo 
        Nombre_Archivo = Nombre_Archivo{1};
        load(strcat(Nombre_Archivo,'.mat')); %Cargar datos del archivo en una variable
        for c = 1 : numParam                 %Promedio del segmento elegido para cada parametro
            JOINNEDDATA((a-1)*numPruebas+b,c) = mean(MetaData(c,analizeBegin:(analizeEnd-1)));  
        end
    end
end

save('JOINNEDDATA.mat', 'JOINNEDDATA');
