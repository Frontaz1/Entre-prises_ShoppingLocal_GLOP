package fr.glop.commerces;

import org.springframework.boot.SpringApplication;

public class TestCommercesApplication {

	public static void main(String[] args) {
		SpringApplication.from(CommercesApplication::main).with(TestcontainersConfiguration.class).run(args);
	}

}
