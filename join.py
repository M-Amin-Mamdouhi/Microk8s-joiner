from flask import Flask, jsonify, request
import subprocess
import re

app = Flask(__name__)

def append_to_hosts(ip, hostname):
    # Append the entry to /etc/hosts if it doesn't already exist
    try:
        with open("/etc/hosts", "a+") as hosts_file:
            hosts_file.seek(0)  # Move to the start of the file
            if f"{ip} {hostname}" not in hosts_file.read():
                hosts_file.write(f"{ip} {hostname}\n")
        return True
    except PermissionError:
        return False

@app.route('/get-join-command', methods=['GET'])
def get_join_command():
    # Capture the requester's IP
    requester_ip = request.remote_addr

    # Retrieve the hostname from the query parameter
    hostname = request.args.get('hostname', 'default-hostname')

    # Append to /etc/hosts
    if not append_to_hosts(requester_ip, hostname):
        return jsonify({"error": "Failed to append to /etc/hosts. Check permissions."}), 500

    # Generate join command
    result = subprocess.run(["sudo", "microk8s", "add-node"], capture_output=True, text=True)

    if result.returncode == 0:
        join_command = result.stdout.strip()

        # Extract specific part of join_command
        pattern = r'microk8s join .+ --worker'
        match = re.search(pattern, join_command)
        if match:
            extracted_command = match.group(0)  # Extract the matched command

            return jsonify({"join_command": extracted_command})
        else:
            return jsonify({"error": "Specific join command not found"})
    else:
        return jsonify({"error": "Failed to generate join command",
                        "stderr": result.stderr, 
                        "stdout": result.stdout}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8081)
