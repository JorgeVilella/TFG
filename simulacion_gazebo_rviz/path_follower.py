#!/usr/bin/env python3

import rospy
import math
import numpy as np
from scipy.spatial import distance
from geometry_msgs.msg import Twist, Pose, PoseStamped, Quaternion, Point

rosRate = 20 
T= 1/rosRate
delta_t = 1/rosRate
i=0
ptos_ref = []

########################################################
#Parámetros para lemniscata pequeña //a = 0.50; b = 0.25; ptos = 10
########################################################
'''
ptos = 10

kp_dist = 1 
ki_dist = 0.5
kd_dist = 1

kp_angle = 3.7 
ki_angle = 2 
kd_angle = 0.2
'''
########################################################
#Parámetros para lemniscata grande //a = 1; b = 0.5; ptos = 20
########################################################

ptos = 30

kp_dist = 1 
ki_dist = 0.5
kd_dist = 1

kp_angle = 3 
ki_angle = 1.5 
kd_angle = 0

#############################################################
#Parámetros para círculo grande //Cx = -1.5; Cy = 0; r = 1.5
#############################################################
'''
ptos = 20

kp_dist = 1 
ki_dist = 0.5 
kd_dist = 1

kp_angle = 0.6 
ki_angle = 0.3 
kd_angle = 0 
'''
#############################################################
#Parámetros para círculo pequeño //Cx = -0.5; Cy = 0; r = 0.5
#############################################################
'''
ptos = 10

kp_dist = 1 
ki_dist = 0.5 
kd_dist = 1

kp_angle = 5 
ki_angle = 1 
kd_angle = 0
'''

sat_dist=0.15
sat_angle=1.5

class path_follower(object):

    def __init__(self):
        self.pub=rospy.Publisher('/cmd_vel',Twist,queue_size=5)
        self.pub_opti=rospy.Publisher('/opti_coords_a_tratar',Twist,queue_size=5)

        self.rate=rospy.Rate(rosRate)
        self.index1 = 0
        self.xrobot_pozyx=0
        self.yrobot_pozyx=0
        self.xrobot_opti=0
        self.yrobot_opti=0
        self.Xref = 0
        self.Yref = 0
        self.ori_z_robot=0
        self.ori_w_robot=0
        self.twist=Twist()

        t = np.linspace(T, 0, ptos)
        self.pathx = []
        self.pathy = []        

        if(tray == '1'):
            #####################
            #Trayectoria circular
            #####################
            
            Cx = 3; Cy = 3; w = 2*math.pi/T
            r = 2
            for i in t:
                self.pathx.append(Cx + r*math.cos(w*i))
                self.pathy.append(Cy + r*math.sin(w*i))
            
        elif(tray == '2'):
            #######################
            #Trayectoria lemniscata
            #######################
            
            a = 2; b = 1; X0 = 3; Y0 = 3; w = 2*math.pi/T
            for i in t:
                self.pathx.append(X0+a*math.sin(w*i))
                self.pathy.append(Y0+b*math.sin(2*w*i))
        elif(tray == '3'):
            self.pathx = [1, 1, 5, 5, 2, 2, 4, 4, 3]
            self.pathy = [1, 6, 6, 1, 2, 4, 5, 2, 3]
        
    def callback_opti_ref(self,data):
        self.Xref = data.pose.position.z
        self.Yref = data.pose.position.x

    def callback_opti_walle(self,data):
        self.xrobot_opti = (data.pose.position.z - self.Xref) * (-1)
        self.yrobot_opti = data.pose.position.x - self.Yref + 1 

    def callback(self,data):
        global i
        self.xrobot_pozyx=data.position.x / 1000
        self.yrobot_pozyx=data.position.y / 1000
            
        #Orientacion con angulos de Euler
        self.ori_x_robot, self.ori_y_robot, self.ori_z_robot=euler_from_quaternion(data.orientation.x,data.orientation.y,data.orientation.z,data.orientation.w)

        #Realimentación con optitrack
        '''
        x_actual=self.xrobot_opti
        y_actual=self.yrobot_opti
        w_actual=self.ori_z_robot
        '''

        #Realimentación con POZYX
        x_actual=self.xrobot_pozyx
        y_actual=self.yrobot_pozyx
        w_actual=self.ori_z_robot

        print("X :", x_actual, "\n", "Y: ", y_actual, "\n", "ORIENTACION :", w_actual)
        
        #Ir al primer punto y localizarse
        size2 = len(self.pathx)
        
        if (i<=(size2-1)):
            p1 = [x_actual,y_actual]
            p3 = [self.pathx[i],self.pathy[i]]
            distance1 = distance.euclidean(p1,p3)
        else:
            i = 0  

        #Calculo del angulo para el setpoint al que se va
        dify=(self.pathy[i]-y_actual)
        difx=(self.pathx[i]-x_actual)
        m=dify/difx
        angle=math.atan(m)

        #Condicion de correcion de la tangente
        if (m>=0):
            if (difx<0):
                angle=angle-math.pi
        else:
            if(difx<0):
                angle=angle+math.pi

        err_dist1=distance1            
        cumerror_dist=err_dist1*delta_t  
        dererror_dist = err_dist1/delta_t
        err_angle=angle-w_actual
        cumerror_angle=err_angle*delta_t
        dererror_angle = err_angle/delta_t
        
        pi_dist=kp_dist*err_dist1 + ki_dist*cumerror_dist + kd_dist*dererror_dist
        pi_angle=kp_angle*err_angle + ki_angle*cumerror_angle + kd_angle*dererror_angle
        
        #Valores de saturacion
        saturated_pi_dist=min(sat_dist,max(-sat_dist,pi_dist))
        saturated_pi_angle=min(sat_angle,max(-sat_angle,pi_angle))

        print("Error ", err_angle)
        print("PTO OBJ: ",self.pathx[i], self.pathy[i])
        
        if(err_angle > 10*math.pi/6):
            saturated_pi_angle = -saturated_pi_angle*0.5
        elif (err_angle < -10*math.pi/6):
            saturated_pi_angle = abs(saturated_pi_angle)*0.5
        if (i<size2):
            if(err_dist1<0.2):
                self.twist.linear.x = 0
                self.twist.angular.z = 0
                ptos_ref.append([self.pathx[i], self.pathy[i]])
                print("LLEGUE AL PUNTO: ", ptos_ref[i])
                i=i+1
            else:
                self.twist.linear.x=saturated_pi_dist
                self.twist.angular.z=saturated_pi_angle
        else:
            self.twist.linear.x = 0
            self.twist.angular.z = 0

    def publicar(self, event = None):
        self.pub.publish(self.twist)
        self.pub_opti.publish(Point(self.xrobot_opti, self.yrobot_opti, 0),
                    Quaternion(0, 0, 0, 0))
        
    def start(self):
        rospy.Subscriber("/mocap_node/Referencia/pose", PoseStamped, self.callback_opti_ref)
        rospy.Subscriber("/mocap_node/Walle/pose", PoseStamped, self.callback_opti_walle)
        rospy.Subscriber("/pozyx_coords", Pose, self.callback)
        rospy.Timer(rospy.Duration(1.0/rosRate), self.publicar)
        rospy.spin()
            
def euler_from_quaternion(x, y, z, w):
        """
        Convert a quaternion into euler angles (roll, pitch, yaw)
        roll is rotation around x in radians (counterclockwise)
        pitch is rotation around y in radians (counterclockwise)
        yaw is rotation around z in radians (counterclockwise)
        """
        t0 = +2.0 * (w * x + y * z)
        t1 = +1.0 - 2.0 * (x * x + y * y)
        roll_x = math.atan2(t0, t1)
     
        t2 = +2.0 * (w * y - z * x)
        t2 = +1.0 if t2 > +1.0 else t2
        t2 = -1.0 if t2 < -1.0 else t2
        pitch_y = math.asin(t2)
     
        t3 = +2.0 * (w * z + x * y)
        t4 = +1.0 - 2.0 * (y * y + z * z)
        yaw_z = math.atan2(t3, t4)
     
        return roll_x, pitch_y, yaw_z # in radians  
            

if __name__ == '__main__':
    #Comienza el nodo
    tray = input("Circulo (1) Lemniscata (2) Manual (3) ")
    rospy.init_node('path_follower')
    path1=path_follower()
    try:
        path1.start()
    except rospy.ROSInterruptException:
        pass  
    
