# Docker-swarm-terraform-ansible-

terraform: dockerswarm.tf:
- create "security group";
- create "key pair";
- create "manager" instance: 
  manager.yml
  - install docker
  - init swarm
  - write in file token for worker nodes
  - add to token managers IP and port 2377
- create "worker1" instance + launch:
  worker.yml
  - install docker
  - read token, IP and port from file 
  - join this node/instance to swarm as a worker
- create "worker2" instance + launch:
  worker.yml
  - install docker
  - read token, IP and port from file 
  - join this node/instance to swarm as a worker
