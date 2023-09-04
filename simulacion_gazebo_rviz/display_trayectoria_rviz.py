#!/usr/bin/env python3

import rospy
from geometry_msgs.msg import Point
import numpy as np
from math import sin, cos, pi
from visualization_msgs.msg import Marker, MarkerArray


global posx, posy, posz, orix, oriy, oriz, oriw, size_anchor
posx=0
posy=0
posz=0
orix=0
oriy=0
oriz=0
oriw=0
X = []
Y = []
i = 0
rosRate = 25
T = 1/rosRate


class MarkerBasics(object):
    global posx, posy, posz, orix, oriy, oriz, oriw
	
    def __init__ (self):
        """Se escoge la trayectoria a mostrar"""
        global posx, posy, tray
        self.marker_arraylisher=rospy.Publisher('/visualization_marker_array', MarkerArray, queue_size=10)
        ptos = 20
        self.rate=rospy.Rate(rosRate)
        
        t = np.linspace(0, T, ptos)
        

        if(tray == '1'):
            #####################
            #Trayectoria circular
            #####################
            
            Cx = 0; Cy = 0; w = 2*pi/T
            r = 1.5
            for i in t:
                X.append(Cx + r*cos(w*i))
                Y.append(Cy + r*sin(w*i))
            
        elif(tray == '2'):
            #######################
            #Trayectoria lemniscata
            #######################
            
            a = 1; b = 0.5; X0 = 0; Y0 = 0; w = 2*pi/T
            for i in t:
                X.append(X0+a*sin(w*i))
                Y.append(Y0+b*sin(2*w*i))
        
        self.init_marker(index=0,z_val=0)
	
    def init_marker(self, index=0, z_val=0):
        self.marker_array = MarkerArray()	
        self.marker_object = Marker()
        self.marker_object.header.frame_id = 'odom'
        self.marker_object.header.stamp = rospy.get_rostime()
        self.marker_object.ns = "map"
        self.marker_object.id = index
        self.marker_object.type = Marker.SPHERE
        self.marker_object.action = Marker.ADD

        my_point=Point()
        my_point.z=z_val
        self.marker_object.pose.position=my_point

        self.marker_object.pose.orientation.x=0
        self.marker_object.pose.orientation.y=0
        self.marker_object.pose.orientation.z=0
        self.marker_object.pose.orientation.w=0
        self.marker_object.scale.x=0.15
        self.marker_object.scale.y=0.15
        self.marker_object.scale.z=0.15

        self.marker_object.color.r=0
        self.marker_object.color.g=1
        self.marker_object.color.b=0
        self.marker_object.color.a=1

        self.marker_object.lifetime=rospy.Duration(0)
		
		
    def start(self):
        global i
        while not rospy.is_shutdown():
            self.marker_object.id = i
            self.marker_object.pose.position.x=posx
            self.marker_object.pose.position.y=posy
            self.marker_object.pose.position.z=posz
            self.marker_object.pose.orientation.x=orix
            self.marker_object.pose.orientation.y=oriy
            self.marker_object.pose.orientation.z=oriz
            self.marker_object.pose.orientation.w=oriw
            if(i < len(X)):
                self.marker_array.markers.append(self.marker_object)
                rospy.loginfo(self.marker_array.markers[i].id)
                self.marker_arraylisher.publish(self.marker_array)
                rospy.sleep(0.5)
            actualiza_coord()



def actualiza_coord():
    global posx, posy, i, id
    if(i < len(X)):
        posx = X[i]
        posy = Y[i]
        i += 1
        
if __name__ == '__main__':
    rospy.init_node('marker_basic_node',anonymous=True)
    tray = input("Circulo (1) o Lemniscata (2): ")
    markerbasics_object=MarkerBasics()
    try:
        markerbasics_object.start()
		
    except rospy.ROSInterruptException:
        pass
