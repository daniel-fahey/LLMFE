# LLM-FE Reproduction Guide

This guide provides step-by-step instructions for reproducing the results from the paper "LLM-FE: Automated Feature Engineering for Tabular Data with LLMs as Evolutionary Optimizers".

## Environment Setup

```bash
# Enter Nix development shell (provides Python, CUDA, secrets via agenix-shell)
nix develop

# Initialize uv project (one-time setup)
uv init --no-readme

# Install Python dependencies from requirements.txt
uv add $(cat requirements.txt | cut -d'=' -f1 | tr '\n' ' ')
```

**Note**: The Nix flake uses `agenix-shell` to securely provide the OpenAI API key via `secrets/openai-api-key.age`. The key is automatically exported as `OPENAI_API_KEY` in the shell environment. The encrypted secrets file must be at least staged in git for Nix to access it.

## Dataset Overview

The paper evaluates on 37 datasets total:
- **8 Binary Classification**: adult, blood-transfusion, bank-marketing, breast-w, credit-g, tic-tac-toe, pc1, pima-indian-diabetes
- **11 Multi-class Classification**: arrhythmia, balance-scale, car, cmc, eucalyptus, jungle_chess, vehicle, cdc-diabetes, heart, communities, myocardial
- **10 Regression**: airfoil_self_noise, cpu_small, diamonds, plasma_retinol, forest-fires, housing, crab, insurance, bike, wine
- **8 Large-scale/High-dimensional**: Additional classification datasets with >50 features

*Note: The current codebase includes 25 datasets in the `data/` directory. Some datasets from the paper may need to be sourced separately.*

## Core Configuration Parameters

### LLM Configuration
- **Backbone Models**: GPT-3.5-Turbo (API) or Llama-3.1-8B-Instruct (local)
- **Temperature**: 0.8 (balances creativity vs adherence to constraints)
- **Samples per iteration**: 3 programs per prompt
- **Total samples**: 20 LLM samples per experiment
- **API Key**: Automatically loaded via agenix-shell as `OPENAI_API_KEY`

### Memory Management (Islands Model)
- **Number of islands**: 3 independent populations
- **Programs per prompt**: 2 in-context examples
- **Clustering**: Programs grouped by validation score signatures
- **Selection**: Boltzmann selection with temperature decay
  - Initial temperature: T₀ = 0.1
  - Decay period: N = 10,000 iterations

### Evaluation Constraints
- **Time limit**: 30 seconds per program evaluation
- **Memory limit**: 2GB per program
- **Cross-validation**: 5-fold stratified (classification) or regular (regression)
- **Train-test split**: 80-20 split with 5 random seeds

## Running Experiments

### Quick Start - Single Dataset
```bash
# Classification example (balance-scale)
uv run python main.py \
  --problem_name balance-scale \
  --spec_path ./specs/specification_balance-scale.txt \
  --log_path ./logs/balance-scale_reproduction

# Regression example (housing)
uv run python main.py \
  --problem_name housing \
  --spec_path ./specs/specification_housing.txt \
  --log_path ./logs/housing_reproduction
```

### Using API Models (OpenAI)
```bash
# OPENAI_API_KEY is automatically available via agenix-shell
uv run python main.py \
  --use_api True \
  --api_model "gpt-3.5-turbo" \
  --problem_name adult \
  --spec_path ./specs/specification_adult.txt \
  --log_path ./logs/adult_gpt3.5
```

### Using Local LLM
```bash
# Option 1: Start local server first
uv run python llm_engine/engine.py \
  --model_path meta-llama/Llama-3.1-8B-Instruct \
  --port 8000

# Option 2: Run with default local settings
uv run python main.py \
  --problem_name heart \
  --spec_path ./specs/specification_heart.txt \
  --log_path ./logs/heart_local
```

### Batch Reproduction
The paper provides example commands in `run_llmfe.sh`. To reproduce systematically:

```bash
# Run all classification datasets
for dataset in balance-scale breast-w blood car cmc credit-g eucalyptus heart pc1 tic-tac-toe vehicle; do
  uv run python main.py \
    --problem_name $dataset \
    --spec_path ./specs/specification_$dataset.txt \
    --log_path ./logs/${dataset}_reproduction
done

# Run all regression datasets  
for dataset in bike crab housing insurance forest-fires wine; do
  uv run python main.py \
    --problem_name $dataset \
    --spec_path ./specs/specification_$dataset.txt \
    --log_path ./logs/${dataset}_reproduction
done
```

## Expected Results

### Performance Expectations
Based on the paper's results, LLM-FE should consistently outperform baselines:
- **vs AutoFeat**: ~2-5% improvement in most datasets
- **vs OpenFE**: ~1-3% improvement across datasets  
- **vs CAAFE**: ~1-2% improvement on average
- **vs FeatLLM**: Significant improvements, especially on complex datasets

### Model Performance
Results should be evaluated on three prediction models:
1. **XGBoost**: Primary comparison model (tree-based)
2. **MLP**: Neural network baseline  
3. **TabPFN**: Transformer foundation model

### Computational Requirements
- **Local LLM**: Requires GPU with ≥8GB VRAM for Llama-3.1-8B
- **API Usage**: ~$1-5 per dataset depending on complexity
- **Runtime**: 10-30 minutes per dataset (varies by size and LLM speed)
- **Storage**: ~1-2GB for logs and intermediate results

## Evaluation Metrics

### Classification Datasets
- **Binary**: AUC-ROC score
- **Multi-class**: Classification accuracy
- **Reporting**: Mean ± std over 5 random seeds

### Regression Datasets  
- **Primary metric**: R² score
- **Alternative**: RMSE for comparison
- **Reporting**: Mean ± std over 5 random seeds

## Troubleshooting

### Common Issues
1. **CUDA out of memory**: Reduce batch size or use smaller model
2. **API rate limits**: Add delays between requests or reduce parallel calls
3. **Dataset not found**: Check `data/` directory and download missing datasets
4. **Timeout errors**: Increase evaluation timeout beyond 30s for complex datasets
5. **API key issues**: Ensure `secrets/openai-api-key.age` is properly encrypted and accessible

### Memory Management
- The islands model helps prevent overfitting to local optima
- If memory issues occur, reduce number of islands or samples per iteration
- Monitor log files for programs that exceed time/memory limits

### Secret Management
- OpenAI API key is managed via agenix-shell and loaded automatically
- No manual key export needed when using `nix develop`
- Key is available as `$OPENAI_API_KEY` environment variable

### Known Issues & Fixes
- **SSL Certificate Error**: Fixed by replacing `http.client` with `requests` library in `llmfe/sampler.py`
- **API Key Environment Variable**: Code now checks both `API_KEY` and `OPENAI_API_KEY`
- **Missing Dependencies**: Run `uv init --no-readme` and add dependencies from `requirements.txt`

### Baseline Comparisons
To reproduce baseline comparisons, ensure:
- Same train-test splits across all methods
- Consistent preprocessing pipelines
- Fair computational budgets (20 LLM calls for all LLM-based methods)

## Output Interpretation

Results are logged to specified log directories containing:
- **Feature transformation programs**: Generated Python code
- **Validation scores**: Performance on each iteration
- **Best features**: Top-performing feature engineering programs
- **Ensemble results**: Final aggregated predictions

The final score represents the ensemble of top-performing programs from each island, following the paper's evaluation protocol.