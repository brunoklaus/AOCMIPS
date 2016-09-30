/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package bitmaptobinary;

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.imageio.ImageIO;

/**
 * A class to read a PNG file and
 * write to a file the rgb values as a sequence of bits.
 * @author bruno.klaus
 */
public class PNGToBinary {

    BufferedImage img = null;   //The PNG image
    
    /**
     * Saves an array of Byte to a file
     * @param filename the name of the file to be created
     * @param bytes the array of Bytes
     */
    public void save (String filename, Byte[] bytes) {
        
        FileOutputStream fos;
        byte[] b = new byte[bytes.length + 2 * 4];
        
        Byte[] size = new Byte[2*4];
        for(int i = 0; i < 2 * 4; i++) {
            size[i] = (byte) 0;
        }
        
        size[0] = (byte)img.getWidth();
        size[4] = (byte) img.getHeight();
        
        //size = this.toLittleEndian(size);
        
        
        for (int i = 0; i < 2 * 4; i++) {
            b[i] = size[i];
        }
        
        for (int i = 0; i < bytes.length; i++) {
            b[i + 2*4] = bytes[i].byteValue();
        }
        
        try {
            fos = new FileOutputStream(filename);
            fos.write(b);
            fos.close();
        } catch (FileNotFoundException ex) {
            Logger.getLogger(PNGToBinary.class.getName()).log(Level.SEVERE, null, ex);
        } catch (IOException ex) {
            Logger.getLogger(PNGToBinary.class.getName()).log(Level.SEVERE, null, ex);
        }
        
    }
    

    public Byte[] toLittleEndian(Byte[] bytes){
        
        if (bytes.length < 4) {
            return bytes;
        }
        
        Byte[] b = new Byte[bytes.length];
        
        for (int i = 0; i < bytes.length / 4; i++) {
            for (int j = 0; j < 4; j++) {
                b[i * 4 + j] = bytes[(i + 1) * 4 - 1 - j].byteValue();
            }
            
        }
        return b;
    }
    
    public Byte[] convertToBinary() throws NullPointerException{
        if (img == null) {
            throw new NullPointerException("Image is null");
        }
        
        int height =  img.getHeight();
        int[] rgbValues = img.getRGB(0, 0, img.getWidth(), img.getHeight(), null, 0, img.getWidth());
        Byte[] bytes = new Byte[rgbValues.length * 4];
        
        
        for (int i = 0; i < rgbValues.length; i++) {
            
            String binaryString = Integer.toBinaryString(rgbValues[i]);
            
            int startIndex = 0;
            for (int j = 0; j < 4; j++) {
                //Get cuurent byte representation
                String currentByteBin = binaryString.substring(startIndex, startIndex + 8);
                int b = Integer.parseInt(currentByteBin, 2);
                
                bytes[i * 4 + j] =  (j == 0)? (byte) b : (byte) b;
                startIndex += 8;
            }
            int a = 0;
            
        }
        
        return bytes;
    }
    
    /**
     * Reads the PNG file.
     * @param filename the name of the file
     */
    public void read(String filename) {
        try {
            File f = new File(filename);
            img = ImageIO.read(f);
            
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
}
