#!/usr/bin/env python3
"""
Production runner for Iran Airspace Monitor on AWS EC2 Windows
Handles logging, error recovery, and production settings
"""

import os
import sys
import logging
import time
from datetime import datetime

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('iran_airspace.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

def main():
    """Main production runner with error recovery"""
    logger.info("Starting Iran Airspace Monitor Production Server")
    logger.info(f"Python version: {sys.version}")
    logger.info(f"Working directory: {os.getcwd()}")
    
    max_retries = 5
    retry_count = 0
    
    while retry_count < max_retries:
        try:
            # Import and run the Flask app
            from app import app, background_tracker
            import threading
            
            # Start background tracker thread
            tracker_thread = threading.Thread(target=background_tracker, daemon=True)
            tracker_thread.start()
            logger.info("Background tracker thread started")
            
            # Run Flask app in production mode
            logger.info("Starting Flask application on 0.0.0.0:5000")
            app.run(
                host='0.0.0.0', 
                port=5000, 
                debug=False,  # Production mode
                threaded=True
            )
            
        except KeyboardInterrupt:
            logger.info("Received shutdown signal, stopping gracefully...")
            break
            
        except Exception as e:
            retry_count += 1
            logger.error(f"Application crashed (attempt {retry_count}/{max_retries}): {e}")
            
            if retry_count < max_retries:
                wait_time = retry_count * 10  # Progressive backoff
                logger.info(f"Restarting in {wait_time} seconds...")
                time.sleep(wait_time)
            else:
                logger.error("Max retries exceeded, shutting down")
                sys.exit(1)

if __name__ == "__main__":
    main() 