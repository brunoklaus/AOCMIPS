/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package bitmaptobinary;

import java.util.Arrays;

/**
 *
 * @author bruno.klaus
 */
public class Main {
    
    static String filename = "gameBG";
    
    public static void main (String[] args) {
      
        PNGToBinary conv = new PNGToBinary();
        conv.read(filename + ".png");
        Byte[] res = conv.toLittleEndian(conv.convertToBinary());
        conv.save(filename + ".KLAUS", res);

        for (int k = 0; k < res.length; k++) {
            Byte b = res[k];
            System.out.println(res[k]);
        }
       
       
    }
    
}
