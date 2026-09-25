package fr.glop.commandes;

import org.springframework.boot.SpringApplication;

public class TestCommandesApplication {

	public static void main(String[] args) {
		SpringApplication.from(CommandesApplication::main).with(TestcontainersConfiguration.class).run(args);
	}

}
