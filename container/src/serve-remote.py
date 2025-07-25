#!/usr/bin/env python3
"""
VS Code Server Remote Launcher
Python replacement for expect script with enhanced error handling
"""

import os
import sys
import time
import logging
import subprocess
from typing import Optional

try:
    import pexpect
except ImportError:
    print("Error: pexpect not installed. Installing...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pexpect"])
    import pexpect

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class VSCodeServerLauncher:
    """Manages VS Code Server remote launch with automatic interaction"""
    
    def __init__(self, timeout: int = 60):
        self.timeout = timeout
        self.runpod_pod_id = os.environ.get('RUNPOD_POD_ID')
        
        if not self.runpod_pod_id:
            raise ValueError("RUNPOD_POD_ID environment variable is not set")
            
        logger.info(f"Initializing VS Code Server for pod: {self.runpod_pod_id}")
    
    def launch_server(self) -> bool:
        """Launch VS Code Server with automatic prompt handling"""
        try:
            logger.info("Starting VS Code Server...")
            
            # Spawn the code-server process
            child = pexpect.spawn(
                'code-server',
                [
                    '--accept-server-license-terms',
                    '--disable-telemetry', 
                    'serve'
                ],
                timeout=self.timeout,
                encoding='utf-8'
            )
            
            # Enable logging of child process output
            if logger.isEnabledFor(logging.DEBUG):
                child.logfile = sys.stdout
            
            logger.info("VS Code Server process started, waiting for prompts...")
            
            # Handle interactive prompts
            while True:
                try:
                    index = child.expect([
                        r'What would you like to call this machine\?',
                        r'Please enter the access token:',
                        r'Error:',
                        pexpect.EOF,
                        pexpect.TIMEOUT
                    ], timeout=30)
                    
                    if index == 0:  # Machine name prompt
                        logger.info(f"Responding to machine name prompt with: {self.runpod_pod_id}")
                        child.sendline(self.runpod_pod_id)
                        
                    elif index == 1:  # Access token prompt
                        logger.warning("Access token required - this might indicate authentication issues")
                        # For RunPod environment, we typically don't need manual token entry
                        break
                        
                    elif index == 2:  # Error occurred
                        logger.error("VS Code Server reported an error")
                        error_line = child.after
                        logger.error(f"Error details: {error_line}")
                        return False
                        
                    elif index == 3:  # EOF - process ended
                        logger.info("VS Code Server process ended")
                        break
                        
                    elif index == 4:  # Timeout
                        logger.info("No more prompts expected, VS Code Server should be running")
                        break
                        
                except pexpect.TIMEOUT:
                    logger.info("Timeout waiting for prompts - server likely started successfully")
                    break
                except pexpect.EOF:
                    logger.info("VS Code Server process completed initialization")
                    break
            
            # Check if process is still running
            if child.isalive():
                logger.info("✅ VS Code Server is running successfully")
                
                # Keep the process alive and log any output
                try:
                    child.expect(pexpect.EOF, timeout=None)  # Wait indefinitely
                except KeyboardInterrupt:
                    logger.info("Received interrupt signal, shutting down...")
                    child.terminate()
                    return True
                    
            else:
                exit_code = child.exitstatus
                logger.warning(f"VS Code Server exited with code: {exit_code}")
                return exit_code == 0
                
            return True
            
        except FileNotFoundError:
            logger.error("code-server command not found. Is VS Code Server installed?")
            return False
        except Exception as e:
            logger.error(f"Failed to launch VS Code Server: {e}")
            return False
    
    def health_check(self) -> bool:
        """Check if VS Code Server is accessible"""
        try:
            import urllib.request
            import urllib.error
            
            # Try to connect to typical VS Code Server port
            health_url = "http://localhost:8000/healthz"
            
            try:
                with urllib.request.urlopen(health_url, timeout=5) as response:
                    if response.status == 200:
                        logger.info("✅ VS Code Server health check passed")
                        return True
            except urllib.error.URLError:
                pass
                
            logger.warning("VS Code Server health check failed - service may not be ready yet")
            return False
            
        except Exception as e:
            logger.warning(f"Health check error: {e}")
            return False

def main():
    """Main entry point"""
    try:
        launcher = VSCodeServerLauncher()
        
        # Launch the server
        success = launcher.launch_server()
        
        if success:
            logger.info("🎉 VS Code Server started successfully")
            
            # Optional health check
            time.sleep(2)  # Give server time to start
            launcher.health_check()
            
            sys.exit(0)
        else:
            logger.error("❌ Failed to start VS Code Server")
            sys.exit(1)
            
    except KeyboardInterrupt:
        logger.info("Interrupted by user")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 