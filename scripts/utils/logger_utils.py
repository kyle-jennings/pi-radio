#!/usr/bin/env python3

"""
Universal Logging Utilities
Provides centralized logging configuration and setup for multiple applications
Automatically detects calling application and configures appropriate logging
"""

import logging
import sys
import os
from pathlib import Path
import inspect

# Default log directory
# DEFAULT_LOG_DIR = "/var/log"
FILE_PATH = os.path.realpath(__file__)
FILE_DIR = os.path.dirname(FILE_PATH) # scripts/utils
SCRIPTS_DIR = os.path.dirname(FILE_DIR)
ROOT_DIR = os.path.dirname(SCRIPTS_DIR)
DEFAULT_LOG_DIR =  ROOT_DIR + '/logs'

def _get_caller_info():
    """
    Get information about the calling application
    
    Returns:
        tuple: (app_name, caller_file_path)
    """
    # Get the caller's frame (skip this function and setup_logging)
    frame = inspect.currentframe()
    try:
        # Go up the call stack to find the actual caller
        caller_frame = frame.f_back.f_back
        if caller_frame is None:
            caller_frame = frame.f_back
        
        caller_file = caller_frame.f_globals.get('__file__', 'unknown')
        app_name = Path(caller_file).stem if caller_file != 'unknown' else 'app'
        
        return app_name, caller_file
    finally:
        del frame

def _get_default_log_file(app_name):
    """
    Generate default log file path based on application name
    
    Args:
        app_name (str): Name of the application
    
    Returns:
        str: Default log file path
    """
    return f"{DEFAULT_LOG_DIR}/{app_name}.log"

def setup_logging(log_file=None, log_level=logging.INFO, app_name=None, 
                 console_output=True, file_output=True, log_format=None):
    """
    Set up logging to file and/or console with automatic application detection
    
    Args:
        log_file (str, optional): Path to log file. Auto-generated if None
        log_level (int, optional): Logging level. Defaults to logging.INFO
        app_name (str, optional): Application name for logger. Auto-detected if None
        console_output (bool, optional): Enable console logging. Defaults to True
        file_output (bool, optional): Enable file logging. Defaults to True
        log_format (str, optional): Custom log format. Uses default if None
    
    Returns:
        logging.Logger: Configured logger instance
    """
    # Auto-detect application info if not provided
    if app_name is None:
        detected_app_name, caller_file = _get_caller_info()
        app_name = detected_app_name
    else:
        _, caller_file = _get_caller_info()
    
    # Generate log file path if not provided
    if log_file is None and file_output:
        log_file = _get_default_log_file(app_name)
    
    logs_dir = os.path.dirname(log_file)
    if not os.path.exists(logs_dir):
        os.makedirs(logs_dir)

    # Set default format if not provided
    if log_format is None:
        log_format = f'%(asctime)s - {app_name} - %(levelname)s - %(message)s'
    
    # Clear any existing handlers to avoid duplicates
    logger = logging.getLogger(app_name)
    if logger.handlers:
        logger.handlers.clear()
    
    # Set up handlers
    handlers = []
    
    if file_output and log_file:
        final_log_file = _setup_log_file(log_file, app_name, caller_file)
        if final_log_file:
            file_handler = logging.FileHandler(final_log_file)
            file_handler.setFormatter(logging.Formatter(log_format))
            handlers.append(file_handler)
    
    if console_output:
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(logging.Formatter(log_format))
        handlers.append(console_handler)
    
    # Configure logging
    logging.basicConfig(
        level=log_level,
        format=log_format,
        handlers=handlers,
        force=True  # Override any existing configuration
    )
    
    logger = logging.getLogger(app_name)
    logger.setLevel(log_level)
    
    if file_output and final_log_file:
        logger.info(f"Logging initialized for {app_name}. Log file: {final_log_file}")
    else:
        logger.info(f"Logging initialized for {app_name} (console only)")
    
    return logger

def _setup_log_file(log_file, app_name, caller_file):
    """
    Set up log file with fallback options
    
    Args:
        log_file (str): Desired log file path
        app_name (str): Application name for fallback
        caller_file (str): Path to calling file for local fallback
    
    Returns:
        str: Final log file path or None if file logging should be disabled
    """
    log_dir = Path(log_file).parent
    
    # Try to create and use the requested log directory
    try:
        if not log_dir.exists():
            log_dir.mkdir(parents=True, exist_ok=True)
        # Test write access
        test_file = log_dir / f".{app_name}_write_test"
        test_file.touch()
        test_file.unlink()
        return log_file
    except (PermissionError, OSError):
        pass
    
    # Fallback 1: Try user's home directory
    try:
        home_log_dir = Path.home() / "logs"
        home_log_dir.mkdir(exist_ok=True)
        home_log_file = home_log_dir / f"{app_name}.log"
        test_file = home_log_dir / f".{app_name}_write_test"
        test_file.touch()
        test_file.unlink()
        return str(home_log_file)
    except (PermissionError, OSError):
        pass
    
    # Fallback 2: Local directory relative to caller
    try:
        if caller_file and caller_file != 'unknown':
            local_dir = Path(caller_file).parent
            local_log_file = local_dir / f"{app_name}.log"
            test_file = local_dir / f".{app_name}_write_test"
            test_file.touch()
            test_file.unlink()
            return str(local_log_file)
    except (PermissionError, OSError):
        pass
    
    # Fallback 3: Current working directory
    try:
        cwd_log_file = Path.cwd() / f"{app_name}.log"
        test_file = Path.cwd() / f".{app_name}_write_test"
        test_file.touch()
        test_file.unlink()
        return str(cwd_log_file)
    except (PermissionError, OSError):
        pass
    
    # If all else fails, disable file logging
    return None

def get_logger(app_name=None):
    """
    Get a logger instance for the specified application
    
    Args:
        app_name (str, optional): Application name. Auto-detected if None
    
    Returns:
        logging.Logger: Logger instance
    """
    if app_name is None:
        app_name, _ = _get_caller_info()
    
    return logging.getLogger(app_name)

def configure_logger(logger_name, log_level=None, console_output=None, 
                    file_output=None, log_format=None):
    """
    Configure an existing logger with new settings
    
    Args:
        logger_name (str): Name of the logger to configure
        log_level (int, optional): New log level
        console_output (bool, optional): Enable/disable console output
        file_output (bool, optional): Enable/disable file output
        log_format (str, optional): New log format
    """
    logger = logging.getLogger(logger_name)
    
    if log_level is not None:
        logger.setLevel(log_level)
        for handler in logger.handlers:
            handler.setLevel(log_level)
    
    if log_format is not None:
        formatter = logging.Formatter(log_format)
        for handler in logger.handlers:
            handler.setFormatter(formatter)
    
    # Handle console/file output changes
    if console_output is not None or file_output is not None:
        # This would require more complex logic to add/remove handlers
        # For now, recommend calling setup_logging again with new parameters
        logger.warning("To change output destinations, call setup_logging() again")

def list_active_loggers():
    """
    List all currently active logger names
    
    Returns:
        list: List of active logger names
    """
    return [name for name in logging.Logger.manager.loggerDict.keys()]

# Convenience functions for common log levels
def setup_debug_logging(**kwargs):
    """Set up logging with DEBUG level"""
    return setup_logging(log_level=logging.DEBUG, **kwargs)

def setup_info_logging(**kwargs):
    """Set up logging with INFO level"""
    return setup_logging(log_level=logging.INFO, **kwargs)

def setup_warning_logging(**kwargs):
    """Set up logging with WARNING level"""
    return setup_logging(log_level=logging.WARNING, **kwargs)

def setup_error_logging(**kwargs):
    """Set up logging with ERROR level"""
    return setup_logging(log_level=logging.ERROR, **kwargs)
