/*Proyecto: Guante_Traductor
Descripción: captura voltaje de 5 flexo en un divisor de voltaje y calcula su resistencia
             captura el estado (1 o 0) de 2 pushbuttons y valor de aceleración dado por el 
             MPU6050, para determinar si hay movimiento o no.
*/

#include<Wire.h>                             //Librería para I2C

const int MPU_addr = 0x68;                   // Dirección en el bus I2C the MPU-6050
const double Grav = 9.81, Umbral = 0.9;
int16_t AcX, AcY, AcZ;                       //Lecturas simples de la aceleración
double AcelX=0, AcelY=0, AcelZ=0, totalAcel; //Aceleraciones promedios y total
float Mov_yesno = 0;                         //Hay movimiento?
float direcAcel = 0;                          //Eje en el que la aceleración de gravedad es mayor  0=nada, 1=ejeX, 2=ejeY 1=ejeZ

const int A1023 = 1023;   
const float VIN = 4.56;                      //Voltaje entregado por Arduino NANO
const float R0 = 9780;                       //Valor real de las resistencias de 10kOhms 
const float R1 = 9730;
const float R2 = 9870;
const float R3 = 9810;
const float R4 = 9840;

float v0 = 1;
float v1 = 1;
float v2 = 1;
float v3 = 1;
float v4 = 1;
float flex0 = 0;                                //Flexoresistencias y sensores touch
float flex1 = 0;
float flex2 = 0;
float flex3 = 0;
float flex4 = 0;
float touch1 = 0;
float touch2 = 0;

void configuracion(){                           //Configuración del MPU6050
  Wire.beginTransmission(MPU_addr);             //Dirección del Dispositivo
  Wire.write(0x6B);                             //Registro de Power Management
  Wire.write(0x0);                              //Nada interesante, salvo que se opera con un reloj de 8MHz  
  Wire.endTransmission();
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x1B);                             //Configuración del gyroscopio - NO SE OCUPA!!!                                 
  Wire.write(0x0);                              //No autotest, rango del gyro: 250°/s
  Wire.endTransmission();  
  Wire.beginTransmission(MPU_addr);                           
  Wire.write(0x1C);                             //Configuración del acelerómetro 
  Wire.write(0x0);                              //No autotest, rango del acelerometro: 2g
  Wire.endTransmission();  
  }

void guardarRegistrosAcel(){

    Wire.beginTransmission(MPU_addr);
    Wire.write(0x3B);                                //Registro ACCEL_XOUT_H
    Wire.endTransmission();
    Wire.requestFrom(MPU_addr,6);                    /*Notar que se leeran 6 registros sucesivos que contienen
                                                     a ACCEL_XOUT_H,ACCEL_XOUT_L,ACCEL_YOUT_H,ACCEL_YOUT_L
                                                     ACCEL_ZOUT_H,ACCEL_ZOUT_L */
    AcX = (Wire.read()<<8|Wire.read());      
    AcY = (Wire.read()<<8|Wire.read());
    AcZ = (Wire.read()<<8|Wire.read());
    AcelX = float(AcX) * 9.8 / 16384 + AcelX;       //Conversión de g´s a m/s^2 y sumatoria para promedio
    AcelY = float(AcY) * 9.8 / 16384 + AcelY;
    AcelZ = float(AcZ) * 9.8 / 16384 + AcelZ;

    }

void setup() {
  
    pinMode(A0,INPUT);    //Dedo pulgar
    pinMode(A1,INPUT);    //Dedo Indice
    pinMode(A2,INPUT);    //Dedo Medio
    pinMode(A6,INPUT);    //Dedo Anular
    pinMode(A7,INPUT);    //Dedo Meñique
    pinMode(2, INPUT);    //Touch 1 - Entre dedos medio e indice
    pinMode(3, INPUT);    //Touch 2 - Yema dedo medio
    Wire.begin();
    Serial.begin(9600);
    configuracion();
}

void loop() {
             
             for(int a = 0; a < 10; a++){
                      v0 = v0 + (double)(analogRead(A0)) * VIN / A1023;       //Dedo Pulgar  
                      v1 = v1 + (double)(analogRead(A1)) * VIN / A1023;       //Dedo Indice
                      v2 = v2 + (double)(analogRead(A2)) * VIN / A1023;       //Dedo Medio
                      v3 = v3 + (double)(analogRead(A6)) * VIN / A1023;       //Dedo Anular
                      v4 = v4 + (double)(analogRead(A7)) * VIN / A1023;       //Dedo Meñique
                      guardarRegistrosAcel();
                      delay(5);                                     
             }
             touch1 = digitalRead(2);
             touch2 = digitalRead(3);
             
              v0 = v0 / 10;           //Promedio   
              v1 = v1 / 10;
              v2 = v2 / 10;
              v3 = v3 / 10;
              v4 = v4 / 10;
              AcelX = AcelX / 10;                             
              AcelY = AcelY / 10;
              AcelZ = AcelZ / 10;

              flex0 = (v0 * R0) / (VIN - v0);                      //Obtencion de resistencia con divisor de voltaje
              flex1 = (v1 * R1) / (VIN - v1);
              flex2 = (v2 * R2) / (VIN - v2);
              flex3 = (v3 * R3) / (VIN - v3);
              flex4 = (v4 * R4) / (VIN - v4);

              totalAcel = sqrt(AcelX*AcelX+AcelY*AcelY+AcelZ*AcelZ);  //Módulo de la aceleración
              totalAcel = abs (Grav - totalAcel);                     //Diferencia absoluta con respecto a la gravedad 
              if(totalAcel > Umbral)  {                               //Umbral a partir del cual se considera movimiento 
                           Mov_yesno = 1;}
              else{Mov_yesno = 0;}

              if (Mov_yesno = 0)            {//Solo si no hay movimiento se envia el dato sobre la posición de la palma
                if (AcelX*AcelX>AcelY*AcelY and AcelX*AcelX>AcelZ*AcelZ){direcAcel = 1;}
                if (AcelY*AcelY>AcelX*AcelX and AcelY*AcelY>AcelZ*AcelZ){direcAcel = 2;}
                if (AcelZ*AcelZ>AcelX*AcelX and AcelZ*AcelZ>AcelY*AcelY){direcAcel = 1;}
                }
              
              Serial.println(flex0,4);    
              Serial.println(flex1,4);
              Serial.println(flex2,4);
              Serial.println(flex3,4);
              Serial.println(flex4,4);  
              Serial.println(touch1,4);   //En la yema del dedo medio
              Serial.println(touch2,4);   // En el costado del dedo medio
              Serial.println(Mov_yesno);
              Serial.println(direcAcel);
              
              v0 = 0; v1 = 0; v2 = 0; v3 = 0; v4 = 0;   
              AcelX=0; AcelY=0; AcelZ=0; direcAcel = 0; 
}
