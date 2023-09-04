#!/usr/bin/env python3
import rospy
from geometry_msgs.msg import Twist, Pose2D
from turtlesim.msg import Pose
from math import sin, cos, pi, sqrt
import numpy as np
import matplotlib.pyplot as plt


ptos = 500
rosRate = 1/(2*pi/ptos)
delta_t = 1/rosRate
X = []
Y = []
Xr = []
Yr = []
Vel = [0]
X_ant = []
Y_ant = []
Xd = []
Yd = []
index = 0
fig, ax = plt.subplots()
V_max = 0.22; W_max = 2
yaw = 0
l = 0.1
k = 0.15
x = 0
y = 0
V = 0
W = 0

class turtle(object):

    def __init__ (self):
        self.vel_pub = rospy.Publisher('/turtle1/cmd_vel', Twist,queue_size=10)
        self.error_pub = rospy.Publisher('/tracking_errors', Pose2D, queue_size=10)
        self.rate=rospy.Rate(rosRate)
        self.linear_speed=0
        self.angular_speed=0
        self.deadman_walle=0
        self.vel_msg = Twist()
        self.error_msg = Pose2D()
        self.vel_msg.linear.y = self.vel_msg.linear.z = self.vel_msg.angular.x = self.vel_msg.angular.y = 0
        

    def odom_callback(self,data):
        global delta_t, yaw, ex, ey, V, W, Xd,Yd, t, t_ant, t0
        
        self.pose_jack=data
        x=self.pose_jack.x
        y=self.pose_jack.y
        yaw=self.pose_jack.theta
        self.deadman_walle=1
		
        
		
        self.error_msg.theta = 0
        self.velocity_controller()
        self.vel_msg.linear.x = V
        self.vel_msg.angular.z = W
        
        if (self.deadman_walle==1):
            twist = Twist()
            twist.linear.x = self.vel_msg.linear.x
            twist.angular.z = self.vel_msg.angular.z
			
            self.vel_pub.publish(twist)
        else:
            twist = Twist()
            self.vel_pub.publish(twist)

    def velocity_controller(self):
        global index,V,W,t       
        if(index != len(Xd)-1):

            V = Xd[index]*cos(yaw)+Yd[index]*sin(yaw)
            Vel.append(V)
            W = -Xd[index]*sin(yaw)/l+Yd[index]*cos(yaw)/l
            index = index+1
        else:
            V = 0
            W = 0
            

    def start(self):
        global t0,X,Y,delta_t,Xd,Yd,t
        t0 = rospy.Time.now().to_sec()
        rospy.Subscriber("/turtle1/pose", Pose, self.odom_callback)
        t = np.linspace(0, 2*pi, ptos)
        
        #####################
        #Trayectoria circular
        #####################
        '''
        Cx = 2; Cy = 2.5
        r = 1.5
        for i in t:
            X.append(Cx + r*cos(i))
            Y.append(Cy + r*sin(i))
        for i in range(len(t)):
            Xd.append(-r*sin(t[i]))
            Yd.append(r*cos(t[i]))
        '''

        #######################
        #Trayectoria lemniscata
        #######################
        alpha = 1.50
        X0 = 2; Y0 = 2.5
        #Coordenadas lemniscata centrada
        for i in t:
            X.append(alpha*sqrt(2)*cos(i) / ((sin(i))**2+1))
            Y.append(alpha*sqrt(2)*cos(i)*sin(i) / (sin(i)**2+1))
        #Coordenadas lemniscata rotada y desplazada
        for i in range(len(X)):
            Xr.append(X0 + X[i]*cos(3*pi/4) + Y[i]*sin(3*pi/4))
            Yr.append(Y0 - X[i]*sin(3*pi/4) + Y[i]*cos(3*pi/4))
        for i in range(1,len(X)):
            Xd.append((Xr[i]-Xr[i-1])/delta_t)
            Yd.append((Yr[i]-Yr[i-1])/delta_t)

        self.rate.sleep()
        rospy.spin()



if __name__ == '__main__':
    rospy.init_node('turtle_controller')
    turtle1=turtle()
    try:
        rospy.Timer(rospy.Duration(delta_t), turtle1.start())
    except rospy.ROSInterruptException:
        pass
