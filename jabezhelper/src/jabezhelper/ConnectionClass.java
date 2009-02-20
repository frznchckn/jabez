/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package jabezhelper;

/**
 *
 * @author tomn
 */
public class ConnectionClass {
    public int recvPort;
    public int sendPort;
    public String ipAddress;
    public boolean udpConnection;
    public String deviceId;
    public boolean valid;

    public ConnectionClass(String ip, int recv, int send, boolean udp, String name) {
        recvPort = recv;
        sendPort = send;
        ipAddress = ip;
        udpConnection = udp;
        deviceId = name;
        valid = false;
    }
}
