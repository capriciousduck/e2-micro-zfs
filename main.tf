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

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  zone    = var.zone
  project = var.project

  provisioner "remote-exec" {
    # Disk are referenced based on the name parameter set in the "additional-disk" resource block
    inline = ["sudo apt update", "sudo apt install python3 zfsutils-linux -y", "sudo zpool create -f myzfs /dev/google-disk-1 /dev/google-disk-2"]

    connection {
      host        = google_compute_instance.zfs.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = var.shell_user
      private_key = file("${var.private_key}")
    }
  }

}

output "server_public_ip" {
  value = google_compute_instance.zfs.network_interface[0].access_config[0].nat_ip
}
