docker run -d \
  --name portainer \
  --restart unless-stopped \
  -p 9443:9443 \
  -p 8000:8000 \
  -v /var/run/containerd/containerd.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
