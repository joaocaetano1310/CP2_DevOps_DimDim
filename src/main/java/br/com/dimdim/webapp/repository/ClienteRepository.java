package br.com.dimdim.webapp.repository;

import br.com.dimdim.webapp.model.Cliente;
import org.springframework.data.jpa.repository.JpaRepository;

// JpaRepository ja traz salvar, buscar, listar e apagar prontos.
public interface ClienteRepository extends JpaRepository<Cliente, Long> {
}
