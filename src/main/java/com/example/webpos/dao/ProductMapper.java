package com.example.webpos.dao;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import com.example.webpos.model.Product;

@Mapper
public interface ProductMapper {
	int deleteByPrimaryKey(String id);

	int insert(Product row);

	Product selectByPrimaryKey(String id);

	List<Product> selectAll();

	int updateByPrimaryKey(Product row);
}
