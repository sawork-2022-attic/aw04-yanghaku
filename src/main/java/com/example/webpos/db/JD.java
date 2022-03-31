package com.example.webpos.db;

import com.example.webpos.model.Product;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import org.springframework.stereotype.Repository;

import java.net.URL;
import java.util.ArrayList;
import java.util.List;

@Repository
public class JD implements PosDB {

    private List<Product> products = null;

    @Override
    public List<Product> getProducts() {
        if (products == null || products.isEmpty()) {
            products = parseJD("Java");
        }
        return products;
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

    public static List<Product> parseJD(String keyword) {
        // 获取请求https://search.jd.com/Search?keyword=java
        String url = "https://search.jd.com/Search?keyword=" + keyword;

        List<Product> list = new ArrayList<>();
        int retryTime = 20;
        while ((retryTime--) != 0) {
            try { // 如果是获取错误, 就重试(不能返回空列表, 否则在缓存状态下, 一直是空的)
                  // 解析网页
                Document document = Jsoup.parse(new URL(url), 10000);
                // 所有js的方法都能用
                Element element = document.getElementById("J_goodsList");
                // 获取所有li标签
                Elements elements = element.getElementsByTag("li");
                // System.out.println(element.html());

                list.clear();
                // 获取元素的内容
                for (Element el : elements) {
                    // 关于图片特别多的网站，所有图片都是延迟加载的
                    String id = el.attr("data-spu");
                    String img = "https:".concat(el.getElementsByTag("img").eq(0).attr("data-lazy-img"));
                    String price = el.getElementsByAttribute("data-price").text();
                    String title = el.getElementsByClass("p-name").eq(0).text();
                    if (title.indexOf("，") >= 0)
                        title = title.substring(0, title.indexOf("，"));

                    Product product = new Product(id, title, Double.parseDouble(price), img);

                    list.add(product);
                }

                if (list.isEmpty())
                    continue; // 如果空的重试

                // 显式等待两秒作为延迟
                Thread.sleep(2000);
                return list;
            } catch (Exception e) { // 如果出错, 重试

            }
        }
        return list;
    }
}
