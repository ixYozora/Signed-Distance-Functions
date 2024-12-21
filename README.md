# Advanced signed distance functions

Einige Fragmentshader, die zeigen, wie man SDFs benutzen und kombinieren kann.

## Installation

Sie brauchen die glsl-Canvas (id: circledev.glsl-canvas) extension aus VS code.


## Usage
Öffnen sie zunächst einen der Shader und dann geben sie folgenden Befehl in der Suchleiste oben in VS Code ein:

(>show glslCanvas)

## Info

blobberius_3D:               In blobberius_3D kann man im glslCanvas mit der Maus die Kamera drehen.
                             Dies ist ein etwas Komplexerer Fragmentshader, der mithilfe eines [Videotutorials](https://youtu.be/Cfe5UQ-1L9Q)                 von Inigo Quilez, entwickelt wurde.

box - und sphere_repetition: Hier sieht man wie man Domain Repetition auf Boxen und Spheren anwenden kann in Kombination mit 
                             Verzerrungstechniken.
                        
lincoln_satoru:              Hier sieht man einen Fragmentshader, der Naiv entwickelt wurde. Der Name ist Program.

smin_smax:                   Hier kann man die unterschieden von Vereinigunstechniken mit ihren smoothen Versionen beobachten.

sun_ray:                     Kombination von Primitiven um eine Sonne mit ihren Lichtstrahlen darzustellen.
