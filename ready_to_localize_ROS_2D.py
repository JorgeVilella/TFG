#!/usr/bin/env python3

from time import sleep
from pypozyx import (POZYX_POS_ALG_UWB_ONLY, POZYX_2D, Coordinates, POZYX_SUCCESS, PozyxConstants, version,
                     DeviceCoordinates, PozyxSerial, get_first_pozyx_serial_port, SingleRegister, DeviceList, PozyxRegisters)
import rospy
from geometry_msgs.msg import Point32



class ReadyToLocalize(object):

    def __init__(self, pozyx, anchors, algorithm=POZYX_POS_ALG_UWB_ONLY, dimension=POZYX_2D, height=0, remote_id=None):
        self.pozyx = pozyx
        self.anchors = anchors
        self.algorithm = algorithm
        self.dimension = dimension
        self.height = height
        self.remote_id = remote_id

    def setup(self):
        """Calibra los anchors de la lista"""
        print("------------POZYX POSITIONING V{} -------------".format(version))
        print("")
        print("- System will manually configure tag")
        print("")
        print("- System will auto start positioning")
        print("")
        if self.remote_id is None:
            self.pozyx.printDeviceInfo(self.remote_id)
        else:
            for device_id in [None, self.remote_id]:
                self.pozyx.printDeviceInfo(device_id)
        print("")
        print("------------POZYX POSITIONING V{} -------------".format(version))
        print("")

        self.setAnchorsManual(save_to_flash=False)
        self.printPublishConfigurationResult()

    def loop(self):
        """Realiza la localización y publica los resultados"""
        position = Coordinates()
        status = self.pozyx.doPositioning(
            position, self.dimension, self.height, self.algorithm, remote_id=self.remote_id)
        if status == POZYX_SUCCESS:
            rospy.loginfo("X: %f Y: %f Z: %f" % (float(position.x), float(position.y), float(position.z)))
            pub.publish(Point32(position.x, position.y, position.z))
        else:
            self.printPublishErrorCode("positioning")

    def printPublishErrorCode(self, operation):
        """Imprime el error Pozyx"""
        error_code = SingleRegister()
        network_id = self.remote_id
        if network_id is None:
            self.pozyx.getErrorCode(error_code)
            print("LOCAL ERROR %s, %s" % (operation, self.pozyx.getErrorMessage(error_code)))
            return
        
        status = self.pozyx.getErrorCode(error_code, self.remote_id)
        if status == POZYX_SUCCESS:
            print("ERROR %s on ID %s, %s" %
                  (operation, "0x%0.4x" % network_id, self.pozyx.getErrorMessage(error_code)))
        else:
            self.pozyx.getErrorCode(error_code)
            print("ERROR %s, couldn't retrieve remote error code, LOCAL ERROR %s" %
                  (operation, self.pozyx.getErrorMessage(error_code)))

    def setAnchorsManual(self, save_to_flash=False):
        """Añade los anchors a la lista de dispositivos Pozyx uno a uno"""
        status = self.pozyx.clearDevices(remote_id=self.remote_id)
        for anchor in self.anchors:
            status &= self.pozyx.addDevice(anchor, remote_id=self.remote_id)
        if len(self.anchors) > 4:
            status &= self.pozyx.setSelectionOfAnchors(PozyxConstants.ANCHOR_SELECT_AUTO, len(self.anchors),
                                                       remote_id=self.remote_id)

        if save_to_flash:
            self.pozyx.saveAnchorIds(remote_id=self.remote_id)
            self.pozyx.saveRegisters([PozyxRegisters.POSITIONING_NUMBER_OF_ANCHORS], remote_id=self.remote_id)
        return status

    def printPublishConfigurationResult(self):
        """Imprime el resultado de la configuración de los anchors"""
        list_size = SingleRegister()

        self.pozyx.getDeviceListSize(list_size, self.remote_id)
        print("List size: {0}".format(list_size[0]))
        if list_size[0] != len(self.anchors):
            self.printPublishErrorCode("configuration")
            return
        device_list = DeviceList(list_size=list_size[0])
        self.pozyx.getDeviceIds(device_list, self.remote_id)
        print("Calibration result:")
        print("Anchors found: {0}".format(list_size[0]))
        print("Anchor IDs: ", device_list)

        for i in range(list_size[0]):
            anchor_coordinates = Coordinates()
            self.pozyx.getDeviceCoordinates(device_list[i], anchor_coordinates, self.remote_id)
            print("ANCHOR, 0x%0.4x, %s" % (device_list[i], str(anchor_coordinates)))
            
    def printPublishAnchorConfiguration(self):
        """Imprime la configuración de los anchors"""
        for anchor in self.anchors:
            print("ANCHOR,0x%0.4x,%s" % (anchor.network_id, str(anchor.coordinates)))
    
    def pozyx_pose_pub():
        global pub
        pub = rospy.Publisher('pozyx_coords', Point32, queue_size=40)
        rospy.init_node('pozyx_coords_node')
        pozyx = PozyxSerial(serial_port)
        r = ReadyToLocalize(pozyx, anchors, algorithm, dimension, height, remote_id)
        r.setup()




if __name__ == "__main__":

    global pub
    serial_port = get_first_pozyx_serial_port()
    if serial_port is None:
        print("No Pozyx connected. Check your USB cable or your driver!")
        quit()

    # ID del tag a localizar
    remote_id = 0x6833

    anchors = [DeviceCoordinates(0x686f, 1, Coordinates(0, 0, 200)),
            DeviceCoordinates(0x6866, 1, Coordinates(-250, 8350, 2150)),
            DeviceCoordinates(0x6865, 1, Coordinates(5420, -970, 2150)),
            DeviceCoordinates(0x6854, 1, Coordinates(4500, 7000, 150))]
    alg = input("UWB(1) o Tracking(2)")
    if (alg =='1'):
        algorithm = PozyxConstants.POSITIONING_ALGORITHM_UWB_ONLY
        rospy.loginfo("UWB algorithm")
    elif(alg =='2'):
        algorithm = PozyxConstants.POSITIONING_ALGORITHM_TRACKING
        rospy.loginfo("TRACKING algorithm")

    dimension = PozyxConstants.DIMENSION_2D

    height = 0
    
    try:
        
        ReadyToLocalize.pozyx_pose_pub()
        rate = rospy.Rate(20)
        while not rospy.is_shutdown():
            ReadyToLocalize.loop()
            rate.sleep()
    except rospy.ROSInterruptException:
        pass