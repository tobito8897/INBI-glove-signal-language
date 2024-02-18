## Sign Language Alphabet Translator Glove

Matlab and Arduino code used for the final bachelor's project.
Code files include data capture, analysis and visualization.


* ### Summary of the project

The communication of people with hearing disabilities with the rest is complicated. Although sign language exists, a minimal part of the population knows it.

In this project, a glove was designed that allows the alphabet of sign language to be translated. By monitoring and processing the information provided by various sensors placed in the glove, an adequate classification of the signs made was achieved. The prototype has the possibility of being adapted to form words through spelling.

The devices used are:
Resistive flexion sensors (to detect finger flexion).
An accelerometer (to analyze hand movement).
A contact sensor (to confirm contact between some fingers).
The sensor's measures are acquired during short intervals of time. During the intervals, the alphabet signs are performed multiple times. An ArduinoTM Nano estimates an average of the measured values. The data is then sent to a Matlab® script wirelessly. Later, these measurements are used to train machine learning models. The model's goal is to classify the alphabet signs.


<p align="center">
<img src="images/Image1.JPG" width="800" align="center">
</p>