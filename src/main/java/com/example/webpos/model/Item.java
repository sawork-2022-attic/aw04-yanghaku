package com.example.webpos.model;

import java.io.Serializable;

public class Item implements Serializable {
    private Product product;
    private int quantity;

    public Product getProduct() {
        return product;
    }

    public Item() {
    }

    public void setProduct(Product product) {
        this.product = product;
    }

    public int getQuantity() {
        return quantity;
    }

    @Override
    public String toString() {
        return "Item [product=" + product + ", quantity=" + quantity + "]";
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    public Item(Product product, int quantity) {
        this.product = product;
        this.quantity = quantity;
    }
}
