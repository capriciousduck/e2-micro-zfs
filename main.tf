# This code is compatible with Terraform 4.25.0 and versions that are backwards compatible to 4.25.0.
# For information about validating this Terraform code, see https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build#format-and-validate-the-configuration

resource "google_compute_disk" "additional-disk" {
  name    = "disk-${count.index}"
  count   = 2
  project = var.project
  zone    = var.zone
  size    = 10

}

resource "google_compute_instance" "zfs" {


  attached_disk {
    source      = google_compute_disk.additional-disk[0].name
    device_name = google_compute_disk.additional-disk[0].name
    mode        = "READ_WRITE"
  }

  attached_disk {
    source      = google_compute_disk.additional-disk[1].name
    device_name = google_compute_disk.additional-disk[1].name
    mode        = "READ_WRITE"
  }

  boot_disk {
    auto_delete = true
    device_name = var.machine_name

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20231213a"
      size  = 10
      type  = "pd-standard"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  machine_type = "e2-micro"

  metadata = {
    # ssh-keys = "${var.shell_user}:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDC2cDCGNL/bbGgdWO/TeNZNJMpR7+YC0RUmwzPQkoDkb8ObFdtC3LW25/PP4qLxHixOJkY5u9Ap6N36ZWU3tTuJKqeyVwH+HzyW5kmDUPaSJl2u05yxJYa/M/T6JA+0MifFjf4ZERATeAtd1ZHjcerAfDGn1tXIdXXe6WgeqJQHobhwkZqj3FfALux1WviS3/+Qear3LJoOpDUskM0keM6lk7X41ZDFMoEEf1CRXLfsJbUOtjuccNaazNQy02J+s3zRyJPqW34pnENQG7c/v3xgkdg801a4/vu5fsrpyYbQjcaueRiQCIDvUcmqaTR6AwDKadJb2k6Xax3LL1OHvGznndiSyQCML2pDtdnqqsUMEiiQJ2sv2ykLmPaq/6rGluqk2lpvUZrPz0aNA8TvmBZBgpMgbamcgoZ7QHJoqBp7GAjeElFs20l6ofEmcXNlSo8DXvtV5FHq4I8U/LqyhDyTwKNI7wMKWqpeM40wpwb8NMKDJw12+z7Vtc56sicQ80= ${var.shell_user}"
    ssh-keys = "${var.shell_user}:${file("zfs.pub")}"
  }

  name = var.machine_name

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    subnetwork = "projects/${var.project}/regions/us-central1/subnetworks/default"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  # service_account {
  #   email  = "271469700147-compute@developer.gserviceaccount.com"
  #   scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  # }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  zone    = var.zone
  project = var.project

  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 zfsutils-linux -y", "sudo zpool create -f myzfs /dev/sdb /dev/sdc"]

    connection {
      host        = google_compute_instance.zfs.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = var.shell_user
      private_key = file("${var.private_key}")
    }
  }

}

output "server_ip" {
  value = google_compute_instance.zfs.network_interface[0].access_config[0].nat_ip
}