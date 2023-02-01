#cloud-config

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Ubuntu Server 22.04 LTS

autoinstall:
  version: 1
  apt:
    geoip: true
    preserve_sources_list: false
    primary:
      - arches: [amd64, i386]
        uri: http://archive.ubuntu.com/ubuntu
      - arches: [default]
        uri: http://ports.ubuntu.com/ubuntu-ports
  early-commands:
    - sudo systemctl stop ssh
  locale: ${vm_guest_os_language}
  keyboard:
    layout: ${vm_guest_os_keyboard}
  network:
    network:
      version: 2
      ethernets:
        ens160:
          addresses: 
          - ${network_address}
          routes: 
            - to: default
              via: ${network_gateway}
          nameservers:
            addresses: ["${network_dns}"]
  identity:
    hostname: ${build_name}
    username: ${build_username}
    password: ${build_password_encrypted}
  ssh:
    install-server: true
    allow-pw: true
  packages:
    - openssh-server
    - open-vm-tools
    - cloud-init
  user-data:
    disable_root: false
    timezone: ${vm_guest_os_timezone}
  late-commands:
    - sed -i -e 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /target/etc/ssh/sshd_config
    - echo '${build_username} ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/${build_username}
    - curtin in-target --target=/target -- chmod 440 /etc/sudoers.d/${build_username}
