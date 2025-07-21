# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LLM-FE is an automated feature engineering framework that uses Large Language Models as evolutionary optimizers for tabular datasets. The system iteratively generates and refines features using structured prompts, selecting high-impact transformations based on model performance.

## Environment Setup

```bash
# Enter development shell with all dependencies
nix develop

# Initialize uv project (one-time setup)
uv init --no-readme

# Install Python dependencies from requirements.txt
uv add $(cat requirements.txt | cut -d'=' -f1 | tr '\n' ' ')
```

## Common Commands

### Running the Pipeline
```bash
# Basic usage with default settings (local LLM)
uv run python main.py --problem_name <dataset_name> --spec_path ./specs/specification_<dataset_name>.txt --log_path <output_path>

# Using API-based LLM (requires API_KEY environment variable)
export API_KEY=<your_api_key>
uv run python main.py --use_api True --api_model "gpt-3.5-turbo" --problem_name <dataset_name> --spec_path ./specs/specification_<dataset_name>.txt --log_path <output_path>

# Example commands are provided in run_llmfe.sh
bash run_llmfe.sh
```

### Local LLM Server (Optional)
```bash
# Start local LLM server for inference
uv run python llm_engine/engine.py --model_path meta-llama/Llama-3.1-8B-Instruct --port <port_number>
```

## Architecture

### Core Components

- **main.py**: Entry point that handles data loading, preprocessing, cross-validation splits, and orchestrates the feature engineering pipeline
- **llmfe/pipeline.py**: Main pipeline orchestrator that coordinates the evolutionary feature engineering process
- **llmfe/config.py**: Configuration management for experiments, experience buffer, and class configurations
- **llmfe/evaluator.py**: Evaluates generated feature transformations and measures their performance
- **llmfe/sampler.py**: LLM sampling interface for generating new feature hypotheses
- **llmfe/buffer.py**: Experience buffer for storing and managing evolved features across iterations

### Data Flow

1. **Data Loading**: CSV datasets with metadata are loaded from `data/` directory
2. **Specification**: Task-specific templates in `specs/` define the problem context and evaluation framework
3. **Prompt Generation**: Domain-specific prompts from `prompts/` guide LLM feature generation
4. **Evolutionary Process**: The pipeline uses evolutionary optimization with multiple islands and experience buffers
5. **Evaluation**: Features are evaluated using cross-validation with XGBoost or other ML models

### Dataset Structure

- **data/**: Contains CSV files and JSON metadata for 25+ classification/regression datasets
- **specs/**: Problem-specific specification templates with evaluation functions
- **prompts/**: Domain and operation-specific prompt templates for LLM guidance

### Key Patterns

- Specifications use `@equation.evolve` decorator for functions to be optimized
- Specifications use `@evaluate.run` decorator for evaluation functions  
- The system supports both local LLMs and API-based models (OpenAI GPT)
- Cross-validation is handled automatically with stratified/regular k-fold splitting
- Feature engineering focuses on tabular data transformations and derived features

## Configuration

The system uses a hierarchical configuration approach:
- `Config` class handles general experiment parameters
- `ClassConfig` specifies LLM and sandbox implementations
- `ExperienceBufferConfig` manages evolutionary algorithm parameters

Default settings are optimized for most use cases, but can be adjusted for specific requirements like API usage, model selection, or evaluation timeouts.

## Development Notes

- The Nix flake provides CUDA support for GPU acceleration
- Use `uv` for Python dependency management instead of pip/conda
- The environment prevents uv from downloading Python versions (uses system Python from Nix)