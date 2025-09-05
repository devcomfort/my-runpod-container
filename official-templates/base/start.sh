#!/bin/bash
set -e

# ---------------------------------------------------------------------------- #
#                          Function Definitions                                #
# ---------------------------------------------------------------------------- #

start_nginx() {
    echo "Starting Nginx service..."
    service nginx start
}

execute_script() {
    local script_path=$1
    local script_msg=$2
    if [[ -f ${script_path} ]]; then
        echo "${script_msg}"
        bash ${script_path}
    fi
}

setup_ssh() {
    # Always ensure sshd started; add key if provided
    echo "Ensuring SSH server is configured..."
    mkdir -p ~/.ssh
    if [[ $PUBLIC_KEY ]]; then
        echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
    fi
    chmod 700 -R ~/.ssh

    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
        ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -q -N ''
        ssh-keygen -lf /etc/ssh/ssh_host_rsa_key.pub
    fi
    if [ ! -f /etc/ssh/ssh_host_dsa_key ]; then
        ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -q -N ''
        ssh-keygen -lf /etc/ssh/ssh_host_dsa_key.pub
    fi
    if [ ! -f /etc/ssh/ssh_host_ecdsa_key ]; then
        ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -q -N ''
        ssh-keygen -lf /etc/ssh/ssh_host_ecdsa_key.pub
    fi
    if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
        ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -q -N ''
        ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
    fi
    service ssh start
}

export_env_vars() {
    echo "Exporting environment variables..."
    printenv | grep -E '^RUNPOD_|^PATH=|^_=' | awk -F = '{ print "export " $1 "=\"" $2 "\"" }' >> /etc/rp_environment
    echo 'source /etc/rp_environment' >> ~/.bashrc
}

start_jupyter() {
    if [[ $JUPYTER_PASSWORD ]]; then
        echo "Starting Jupyter Lab..."
        mkdir -p /workspace && \
        cd / && \
        nohup python3.10 -m jupyter lab --allow-root --no-browser --port=8888 --ip=* --FileContentsManager.delete_to_trash=False --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' --ServerApp.token=$JUPYTER_PASSWORD --ServerApp.allow_origin=* --ServerApp.preferred_dir=/workspace &> /jupyter.log &
        echo "Jupyter Lab started"
    fi
}

start_filebrowser() {
    if [[ "${ENABLE_FILEBROWSER:-1}" == "1" ]]; then
        filebrowser --address=0.0.0.0 --port=4040 --root=/ --noauth &
    fi
}

start_http_server() {
    if [[ "${ENABLE_HTTP_SERVER:-1}" == "1" ]]; then
        nohup python3 -m http.server 8088 --bind 0.0.0.0 --directory /workspace >/http.server.log 2>&1 &
    fi
}

# ---------------------------------------------------------------------------- #
#                               Main Program                                   #
# ---------------------------------------------------------------------------- #

start_nginx
if [[ -f /etc/runpod/services.env ]]; then
    # shellcheck disable=SC1091
    source /etc/runpod/services.env
fi
execute_script "/pre_start.sh" "Running pre-start script..."

echo "Pod Started"
setup_ssh
start_jupyter
start_filebrowser
start_http_server
export_env_vars

execute_script "/post_start.sh" "Running post-start script..."
echo "Start script(s) finished, Pod is ready to use."
sleep infinity


