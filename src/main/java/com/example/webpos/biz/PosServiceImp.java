package com.example.webpos.biz;

import com.example.webpos.db.PosDB;
import com.example.webpos.model.Cart;
import com.example.webpos.model.Item;
import com.example.webpos.model.Product;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Component;

import java.io.Serializable;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

@Component
public class PosServiceImp implements PosService, Serializable {
    static final Logger logger = LoggerFactory.getLogger(PosServiceImp.class);

    private PosDB posDB;

    @Autowired
    public void setPosDB(PosDB posDB) {
        this.posDB = posDB;
    }

    @Override
    public Product randomProduct() {
        return products().get(ThreadLocalRandom.current().nextInt(0, products().size()));
    }

    @Override
    public void checkout(Cart cart) {

    }

    @Override
    public Cart add(Cart cart, Product product, int amount) {
        return add(cart, product.getId(), amount);
    }

    @Override
    public Cart add(Cart cart, String productId, int amount) {

        Product product = posDB.getProduct(productId);
        if (product == null)
            return cart;

        cart.addItem(new Item(product, amount));
        return cart;
    }

    @Override
    @Cacheable(value = "productsAll")
    public List<Product> products() {
        logger.info("No cache or cache missing, generate products from posDB");
        long start = System.currentTimeMillis();
        List<Product> product = posDB.getProducts();
        logger.info("generate products token " + (System.currentTimeMillis() - start) + " ms");
        return product;
    }
}
