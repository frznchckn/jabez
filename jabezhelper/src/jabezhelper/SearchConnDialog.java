/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/*
 * SearchConnDialog.java
 *
 * Created on Feb 18, 2009, 1:30:29 PM
 */

package jabezhelper;

import javax.swing.table.*;
import javax.swing.event.*;
import javax.swing.*;
import java.util.*;
import java.net.*;

import com.illposed.osc.*;
import com.illposed.osc.utility.*;

/**
 *
 * @author tomn
 */
public class SearchConnDialog extends javax.swing.JDialog {

    private final String[] columnNames = {"  Device", "  Select"};
    private MyTableModel tableModel;
    private static volatile Thread currentThread;
    protected OSCByteArrayToJavaConverter converter;
	protected jabezhelper.OSCPacketDispatcher dispatcher;
    private HashMap foundConnections;
    private DatagramSocket socket;

    /** Creates new form SearchConnDialog */
    public SearchConnDialog(java.awt.Frame parent, boolean modal) {
        super(parent, modal);
        initComponents();

        tableModel = new MyTableModel();
        jTable1.setModel(tableModel);
        jTable1.getTableHeader().setReorderingAllowed(false);
        jTable1.getSelectionModel().setSelectionMode(ListSelectionModel.SINGLE_INTERVAL_SELECTION);
        for (int i = 0; i < columnNames.length; i++) {
            tableModel.addColumn(columnNames[i]);
        }
        jTable1.getColumnModel().getColumn(0).setPreferredWidth(240);
        ListSelectionModel rowSelectionModel = jTable1.getSelectionModel();
        rowSelectionModel.addListSelectionListener(new ListSelectionListener() {
            public void valueChanged(ListSelectionEvent evt) {
                if (evt.getValueIsAdjusting()) return;
                tableRowSelected();
            }
        });

        jProgressBar1.setVisible(false);

        foundConnections = new HashMap();

        // setup the handler for osc messages
        converter =  new OSCByteArrayToJavaConverter();
        dispatcher = new OSCPacketDispatcher();
       	OSCListener listener = new OSCListener() {
    		public void acceptMessage(java.util.Date time, OSCMessage message) {
                Object args[] = message.getArguments();
                if (args.length >= 4) {
//                    System.out.println("found " + args[0] + " " + args[1] + " " + args[2] + " " + args[3]);
                    int sendport = ((Integer) args[1]).intValue();
                    int recvport = ((Integer) args[2]).intValue();

                    if (args.length >= 5) {
                        int id = ((Integer) args[4]).intValue();
//                        System.out.println("device id " + id);
                        recvport += id;     // offset the old port number with the deviceid
                    }

                    String name = ((String) args[3]) + " " + recvport;
                    ConnectionClass conn = new ConnectionClass((String) args[0], recvport, sendport, true, name);
                    Object row[] = { args[3] + " @" + args[0], Boolean.FALSE };
                    foundConnections.put(tableModel.getRowCount(), conn);
                    tableModel.addRow(row);

                }
            }
        };
        dispatcher.addListener(listener);
        jButton3ActionPerformed(null);
    }

    public HashMap showWindow() {
        setLocationRelativeTo(null);
        setVisible(true);
        return foundConnections;
    }

    private void tableRowSelected() {
        boolean rowSelected = false;
        for (int i=0; i<tableModel.getRowCount(); i++) {
            Boolean selected = (Boolean) tableModel.getValueAt(i, 1);
            if (selected == Boolean.TRUE) {
                ConnectionClass conn = (ConnectionClass) foundConnections.get(i);
                conn.valid = true;
                foundConnections.remove(i);
                foundConnections.put(i, conn);
                rowSelected = true;
            }            
        }
        jTable1.clearSelection();
        jButton2.setEnabled(rowSelected);
    }

    private void startNetworkThread() {
        Thread t = new Thread(new ProbeNetwork());
        currentThread = t;
        foundConnections.clear();       // clear current list
        tableModel.setRowCount(0);
        t.start();
    }

    private class ProbeNetwork implements Runnable {
        public void run() {
            try {
                socket = new DatagramSocket(10000);

                // default osc discovery message
                OSCMessage msg = new OSCMessage("/network/find");
                byte[] data = msg.getByteArray();

                // create a broadcast datagram then send it
                socket.send(new DatagramPacket(data, data.length,
                            InetAddress.getByName("255.255.255.255"), 10000));

                // setup the receiving datagram
                byte buffer[] = new byte[1536];
                DatagramPacket dp = new DatagramPacket(buffer, buffer.length);

                while (currentThread == Thread.currentThread()) {
                    socket.receive(dp);
                    if ((buffer[0] == '/') || (buffer[0] == '#')) {     //osc message
                        OSCPacket oscPacket = converter.convert(buffer, dp.getLength());
                        dispatcher.dispatchPacket(oscPacket);
                    }
                }
            } catch (Exception err) {
                System.out.println(err.toString());
            }
        }
    }

    private class MyTableModel extends DefaultTableModel {
        private final Class[] types = new Class[] { java.lang.Object.class, java.lang.Boolean.class };
        private final Boolean[] editable = { Boolean.FALSE, Boolean.TRUE };

        public Class getColumnClass(int col) {
            return types[col];
        }

        public boolean isCellEditable(int row, int col) {
            return editable[col];
        }
    }

    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        jPanel1 = new javax.swing.JPanel();
        jScrollPane1 = new javax.swing.JScrollPane();
        jTable1 = new javax.swing.JTable();
        jPanel2 = new javax.swing.JPanel();
        jPanel3 = new javax.swing.JPanel();
        jProgressBar1 = new javax.swing.JProgressBar();
        jPanel5 = new javax.swing.JPanel();
        jButton3 = new javax.swing.JButton();
        jPanel4 = new javax.swing.JPanel();
        jButton1 = new javax.swing.JButton();
        jButton2 = new javax.swing.JButton();

        setDefaultCloseOperation(javax.swing.WindowConstants.DISPOSE_ON_CLOSE);
        setResizable(false);

        jPanel1.setBorder(javax.swing.BorderFactory.createEmptyBorder(10, 10, 10, 10));
        jPanel1.setLayout(new java.awt.BorderLayout());

        jScrollPane1.setPreferredSize(new java.awt.Dimension(375, 180));

        jTable1.setRowHeight(22);
        jTable1.setRowMargin(2);
        jScrollPane1.setViewportView(jTable1);

        jPanel1.add(jScrollPane1, java.awt.BorderLayout.PAGE_START);

        getContentPane().add(jPanel1, java.awt.BorderLayout.CENTER);

        jPanel2.setBorder(javax.swing.BorderFactory.createEmptyBorder(0, 10, 0, 10));
        jPanel2.setPreferredSize(new java.awt.Dimension(400, 60));
        jPanel2.setLayout(new java.awt.BorderLayout());

        jPanel3.setPreferredSize(new java.awt.Dimension(400, 10));
        jPanel3.setLayout(new java.awt.BorderLayout());

        jProgressBar1.setIndeterminate(true);
        jPanel3.add(jProgressBar1, java.awt.BorderLayout.CENTER);

        jPanel2.add(jPanel3, java.awt.BorderLayout.NORTH);

        jPanel5.setPreferredSize(new java.awt.Dimension(120, 50));
        jPanel5.setLayout(new java.awt.FlowLayout(java.awt.FlowLayout.LEFT, 5, 10));

        jButton3.setText("Search");
        jButton3.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton3ActionPerformed(evt);
            }
        });
        jPanel5.add(jButton3);

        jPanel2.add(jPanel5, java.awt.BorderLayout.WEST);

        jPanel4.setLayout(new java.awt.FlowLayout(java.awt.FlowLayout.RIGHT, 5, 10));

        jButton1.setText("Cancel");
        jButton1.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton1ActionPerformed(evt);
            }
        });
        jPanel4.add(jButton1);

        jButton2.setText("Connect");
        jButton2.setEnabled(false);
        jButton2.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton2ActionPerformed(evt);
            }
        });
        jPanel4.add(jButton2);

        jPanel2.add(jPanel4, java.awt.BorderLayout.CENTER);

        getContentPane().add(jPanel2, java.awt.BorderLayout.SOUTH);

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void jButton1ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton1ActionPerformed
        foundConnections.clear();
        dispose();
    }//GEN-LAST:event_jButton1ActionPerformed

    private void jButton3ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton3ActionPerformed
        // make sure there is nothing in progress
        if (jProgressBar1.isVisible()) return;
        else jProgressBar1.setVisible(true);

        startNetworkThread();

        java.util.Timer timer = new java.util.Timer();
        timer.schedule(new TimerTask() {
            public void run() {
                // do this here so the thread would terminate
                if (socket != null) socket.close();
                currentThread = null;
                jProgressBar1.setVisible(false);
            }
        }, 1000);
        timer = null;
    }//GEN-LAST:event_jButton3ActionPerformed

    private void jButton2ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton2ActionPerformed
        dispose();
    }//GEN-LAST:event_jButton2ActionPerformed

    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JButton jButton1;
    private javax.swing.JButton jButton2;
    private javax.swing.JButton jButton3;
    private javax.swing.JPanel jPanel1;
    private javax.swing.JPanel jPanel2;
    private javax.swing.JPanel jPanel3;
    private javax.swing.JPanel jPanel4;
    private javax.swing.JPanel jPanel5;
    private javax.swing.JProgressBar jProgressBar1;
    private javax.swing.JScrollPane jScrollPane1;
    private javax.swing.JTable jTable1;
    // End of variables declaration//GEN-END:variables

}
