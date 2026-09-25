package fr.glop.fidelite;

import org.springframework.boot.SpringApplication;

public class TestFideliteApplication {

	public static void main(String[] args) {
		SpringApplication.from(FideliteApplication::main).with(TestcontainersConfiguration.class).run(args);
	}

}
