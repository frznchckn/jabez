/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/*
 * UdpViewer.java
 *
 * Created on Feb 16, 2009, 4:47:18 PM
 */

package jabezhelper;
import java.net.*;
import java.util.*;
import java.text.SimpleDateFormat;
import com.illposed.osc.*;
import com.illposed.osc.utility.*;


/**
 *
 * @author Tom
 */
public class UdpViewer extends javax.swing.JPanel implements Runnable {

    private DatagramSocket socket;
    private int recvport, sendport;
    private boolean switchSenderRequested;
    private InetAddress address;
	protected OSCByteArrayToJavaConverter converter;
	protected jabezhelper.OscPacketDispatcher dispatcher;
    protected SimpleDateFormat lFormat = new SimpleDateFormat( "HH:mm:ss:SSS: ");

    /** Creates new form UdpViewer */
    public UdpViewer(ConnectionClass conn, boolean switchSender) {
        initComponents();

        // set up the client address and port number
        try {
            this.recvport = conn.recvPort;
            this.sendport = conn.sendPort;
            this.switchSenderRequested = switchSender;

            if (conn.ipAddress.length() > 0) {
                this.address = InetAddress.getByName(conn.ipAddress);
            }
        } catch (Exception err) {
            jTextArea1.append("*** ERROR *** " + err.toString() + "\n");
        }


        // setup the handler for osc messages
        converter =  new OSCByteArrayToJavaConverter();
        dispatcher = new jabezhelper.OscPacketDispatcher();

       	OSCListener listener = new OSCListener() {
    		public void acceptMessage(java.util.Date time, OSCMessage message) {
                // setup the timestamp down to millisec (time arg is gabarage)
                Date lDate = new Date(System.currentTimeMillis());

                // print the osc message
                jTextArea1.append(lFormat.format(lDate) + message.getAddress());
                for (Object obj : message.getArguments()) {
                    jTextArea1.append(" " + obj.toString());
                }
                jTextArea1.append("\n");

                // automatically scroll for osc message
                jTextArea1.setCaretPosition(jTextArea1.getDocument().getLength());
            }
        };
        dispatcher.addListener(listener);

    }

    public void run() {
        try {
            // print an info message
            jTextArea1.append("Open UDP connection to  ");
            if (address != null) jTextArea1.append(address.getHostAddress());
            else jTextArea1.append("TBD");
            jTextArea1.append("  recv: " + recvport + "  send: " + sendport + "\n");

            byte buffer[] = new byte[1536];
            socket = new DatagramSocket(recvport);
            DatagramPacket dp = new DatagramPacket(buffer, buffer.length);

            // there is a request to device to switch sending port (our receive)
            if (switchSenderRequested) {
                sendOSCString("/network/osc_udp_send_port " + recvport);
            }

            // data receiving loop
            while (true) {
                socket.receive(dp);
                // set client ip address if we didn't know
                if (address == null) {
                    address = dp.getAddress();
                    jTextArea1.append("Receiving UDP data from " + address.getHostAddress() + "\n");
                }

                if ((buffer[0] == '/') || (buffer[0] == '#')) {     //osc message
                    OSCPacket oscPacket = converter.convert(buffer, dp.getLength());
                    dispatcher.dispatchPacket(oscPacket);
                }
                else
                    appendText(new String(buffer, 0, dp.getLength()));
            }
        } catch (Exception err) {
            jTextArea1.append("*** ERROR *** " + err.toString() + "\n");
        }
    }

    public boolean isReady() {
        return ((socket != null) && (socket.isBound()));
    }

    public void closeConnection() {
        socket.close();
    }

    public int getReceivePort() {
        return recvport;
    }

    public void sendOSCString(String str) {
        String segs[] = str.split(" ");
        OSCMessage msg;
        if (segs.length > 1)
            msg = new OSCMessage(segs[0], parseOscString(segs));
        else
            msg = new OSCMessage(segs[0]);

        byte[] buffer = msg.getByteArray();
        jTextArea1.append("osc> ");
        sendData(buffer);
    }

    public void sendRawString(String str) {
        jTextArea1.append("raw> ");
        sendData(str.getBytes());
    }

    private void sendData(byte[] data) {
        try {
            DatagramPacket dp = new DatagramPacket(data, data.length, address, sendport);
            socket.send(dp);
            jTextArea1.append(new String(data, 0, data.length) + "\n");
        } catch (Exception err) {
            jTextArea1.append("*** ERROR *** unable to send data" + "\n");
        }
    }

    private Object[] parseOscString(String[] segs) {
        Object args[] = new Object[segs.length];
        for (int i=1; i<segs.length; i++) {
            try {
                if (segs[i].contains("."))
                    args[i] = Float.valueOf(segs[i]);
                else
                    args[i] = Integer.valueOf(segs[i]);
            } catch (NumberFormatException err) {
                args[i] = segs[i];
            } catch (NullPointerException err) {  // not possible
                jTextArea1.append("*** ERROR *** " + err.toString() + "\n");
            }
        }
        return args;
    }

    private void appendText(String str) {
        // setup the timestamp down to millisec
        Date lDate = new Date(System.currentTimeMillis());

        // determine whether the scrollbar is currently at the very bottom position.
        javax.swing.JScrollBar vbar = jScrollPane1.getVerticalScrollBar();
        boolean autoScroll = ((vbar.getValue() + vbar.getVisibleAmount()) == vbar.getMaximum());
        jTextArea1.append(lFormat.format(lDate) + str + "\n");

        // now scroll if we were already at the bottom.
        if (autoScroll) jTextArea1.setCaretPosition(jTextArea1.getDocument().getLength());
    }

    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        jScrollPane1 = new javax.swing.JScrollPane();
        jTextArea1 = new javax.swing.JTextArea();

        setLayout(new java.awt.BorderLayout());

        jScrollPane1.setVerticalScrollBarPolicy(javax.swing.ScrollPaneConstants.VERTICAL_SCROLLBAR_ALWAYS);

        jTextArea1.setColumns(20);
        jTextArea1.setEditable(false);
        jTextArea1.setRows(5);
        jTextArea1.setMargin(new java.awt.Insets(0, 8, 0, 0));
        jScrollPane1.setViewportView(jTextArea1);

        add(jScrollPane1, java.awt.BorderLayout.CENTER);
    }// </editor-fold>//GEN-END:initComponents


    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JScrollPane jScrollPane1;
    private javax.swing.JTextArea jTextArea1;
    // End of variables declaration//GEN-END:variables

}
