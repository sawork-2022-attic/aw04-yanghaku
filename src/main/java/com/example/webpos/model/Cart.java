package com.example.webpos.model;

import org.springframework.stereotype.Component;
import org.springframework.web.context.annotation.SessionScope;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

@Component
@SessionScope
public class Cart implements Serializable {

    private List<Item> items = new ArrayList<>();

    public boolean addItem(Item item) {
        return items.add(item);
    }

    public void clear() {
        items.clear();
    }

    public void deleteItem(String productId) {
        for (int i = 0; i < items.size(); ++i) {
            if (items.get(i).getProduct().getId().equals(productId)) {
                items.remove(i);
                break;
            }
        }
    }

    public void modifyItem(String productId, int amount) {
        for (int i = 0; i < items.size(); ++i) {
            if (items.get(i).getProduct().getId().equals(productId)) {
                items.get(i).setQuantity(amount);
            }
        }
    }

    public List<Item> getItems() {
        return items;
    }

    public void setItems(List<Item> items) {
        this.items = items;
    }

    public double getTotal() {
        double total = 0;
        for (int i = 0; i < items.size(); i++) {
            total += items.get(i).getQuantity() * items.get(i).getProduct().getPrice();
        }
        return total;
    }

}
