package com.example.webpos.db;

import com.example.webpos.dao.ProductMapper;
import com.example.webpos.model.Product;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class mysql implements PosDB {
	static final Logger logger = LoggerFactory.getLogger(PosDB.class);

	private ProductMapper productMapper;

	private List<Product> products;

	@Autowired
	public void setProductMapper(ProductMapper p) {
		this.productMapper = p;
		this.products = this.productMapper.selectAll();
	}

	@Override
	public List<Product> getProducts() {
		return this.products;
	}

	@Override
	public Product getProduct(String productId) {
		for (Product p : getProducts()) {
			if (p.getId().equals(productId)) {
				return p;
			}
		}
		return null;
	}
}
