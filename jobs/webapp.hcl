# Create a job named webapp.
job "webapp" {
  region      = "global"
  datacenters = ["us-east-1"]

  # This is a service job.
  type = "service"

  # Perform rolling updates, one at a time.
  update {
    stagger      = "30s"
    max_parallel = 1
  }

  # Restrict to only nodes running linux.
  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  # Our task group for the servers.
  group "web" {
    count = 1

    task "darkhttpd" {
      driver = "docker"

      config {
        image = "hashitraining/web"
        port_map {
          http = 80
        }
      }

      # Tell the container where Consul lives.
      env {
        "CONSUL_HTTP_ADDR" = "${meta.host_ip}:8500"
      }

      service {
        name = "web"
        port = "http"
        check {
          type     = "http"
          path     = "/"
          interval = "5s"
          timeout  = "1s"
        }
      }

      resources {
        cpu    = 500
        memory = 256
        network {
          mbits = 100
          port "http" {}
        }
      }
    }
  }

  group "lb" {
    count = 1

    task "haproxy" {
      driver = "docker"

      config {
        image = "hashitraining/lb"
        port_map {
          http = 80
        }
      }

      # Tell the container where Consul lives.
      env {
        "CONSUL_HTTP_ADDR" = "${meta.host_ip}:8500"
      }

      service {
        name = "lb"
        port = "http"
        check {
          type     = "http"
          path     = "/"
          interval = "5s"
          timeout  = "1s"
        }
      }

      resources {
        cpu    = 500
        memory = 256
        network {
          mbits = 100
          port "http" {
            static = 80
          }
        }
      }
    }
  }
}
