%Proyecto: Guante_Traductor
%Descripcion: captura datos de 5 flexo, 2 pushbuttons y movimiento de acelerometro 
%             por 7 segundos y los guarda en un archivo.

clc;                                                    %Limpiar y cerrar todo
clear all;
close all;

delete(instrfind({'Port'},{'COM5'}));                   %Configurar el puerto
puerto_s=serial('COM5');                             
puerto_s.Baudrate=9600;                                 
warning('Off','MATLAB:serial:fscanf:unsuccessfulRead');
      
%Variables
cont_time = 1;
tTest = 7;                            %Tiempo de duracion de la prueba
fS = 20;                              %Frecuencia de muestreo (determinada por el Arduino)
numParam = 9;                         %Numero de parametros

Received_Data = zeros(1,numParam);    %Datos leidos del puerto
tiempo = zeros(1,tTest*fS);           %Vector del tiempo
MetaData = zeros(numParam+1,tTest*fS);%Matriz para almacenar datos y el vector de tiempo

fopen(puerto_s);        %Abrir el puerto        
flushinput(puerto_s);   %Borra el buffer del COM
d=[];

while(cont_time <= tTest*fS)  
    %Escanear puerto para leer datos
	d = fscanf(puerto_s,'%f'); MetaData(1,cont_time) = d(1);   %Flexo0 - Pulgar
    d = fscanf(puerto_s,'%f'); MetaData(2,cont_time) = d(1);   %Flexo1 - Indice
    d = fscanf(puerto_s,'%f'); MetaData(3,cont_time) = d(1);   %Flexo2 - Medio
    d = fscanf(puerto_s,'%f'); MetaData(4,cont_time) = d(1);   %Flexo3 - Anular
    d = fscanf(puerto_s,'%f'); MetaData(5,cont_time) = d(1);   %Flexo4 - Menique
    d = fscanf(puerto_s,'%f'); MetaData(6,cont_time) = d(1);   %Touch1 - Entre dedos medio e indice
    d = fscanf(puerto_s,'%f'); MetaData(7,cont_time) = d(1);   %Touch2 - Yema dedo medio 
    d = fscanf(puerto_s,'%f'); MetaData(8,cont_time) = d(1);   %Movimiento
    d = fscanf(puerto_s,'%f'); MetaData(9,cont_time) = d(1);   %Direccion del Acelerometro
    
	tiempo(cont_time) = cont_time/20; %Incremento del vector de tiempo
    disp(floor(cont_time/20));        %Impresi�n el tiempo
    
    cont_time = cont_time + 1;
end                                                           
                                    
disp('FIN!')
MetaData(numParam+1,:) = tiempo;
save('Z_p10.mat', 'MetaData'); %Guardar datos
fclose(puerto_s)