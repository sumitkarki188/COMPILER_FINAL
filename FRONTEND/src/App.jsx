import React, { useState, useRef } from 'react';
import Editor from '@monaco-editor/react';
import axios from 'axios';
import * as monaco from 'monaco-editor';
import './index.css';

function App() {
  const [code, setCode] = useState('');
  const [language, setLanguage] = useState('');
  const [suggestion, setSuggestion] = useState('');
  const [score, setScore] = useState(null);
  const [accepted, setAccepted] = useState(null);
  const [errors, setErrors] = useState([]);
  const [loadingSuggestion, setLoadingSuggestion] = useState(false);
  const [loadingSyntax, setLoadingSyntax] = useState(false);
  const [theme, setTheme] = useState('vs-dark');

  const editorRef = useRef(null);

  const removeComments = (code) => {
    return code
      .replace(/\/\/.*$/gm, '')          
      .replace(/\/\*[\s\S]*?\*\//g, '')  
      .replace(/#.*$/gm, '')             
      .trim();
  };

  const detectLanguage = async (newCode) => {
    try {
      const res = await axios.post('http://localhost:5000/detect_language', { code: newCode });
      const detected = res.data.language;
      const monacoLang = detected === 'c' ? 'cpp' : detected;
      setLanguage(monacoLang);
    } catch (err) {
      console.error('Language detection failed:', err);
    }
  };

  const handleEditorChange = (value) => {
    setCode(value);
    detectLanguage(value);
  };

  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async (event) => {
      const text = event.target.result;
      setCode(text);
      detectLanguage(text);
    };
    reader.readAsText(file);
  };

  const handleFormat = () => {
    if (editorRef.current) {
      editorRef.current.getAction('editor.action.formatDocument').run();
    }
  };

  const handleMLSuggestion = async () => {
    setLoadingSuggestion(true);
    setSuggestion('');
    setScore(null);
    setAccepted(null);
    try {
      const res = await axios.post('http://localhost:5000/ml_suggest', {
        code,
        language,
      });
      setSuggestion(res.data.suggestion);

      const scoreRes = await axios.post('http://localhost:5000/score', {
        original: code,
        corrected: res.data.suggestion,
      });
      setScore(scoreRes.data.similarity);
    } catch (err) {
      setSuggestion('Error: ' + err.message);
    }
    setLoadingSuggestion(false);
  };

  const handleSyntaxCheck = async () => {
    setLoadingSyntax(true);
    setErrors([]);
    try {
      const res = await axios.post('http://localhost:5000/syntax_check', {
        code,
        language,
      });
      const errs = res.data.errors || [];
      setErrors(errs);

      if (editorRef.current) {
        const model = editorRef.current.getModel();
        const markers = errs.map((line, i) => {
          const match = line.match(/line (\d+)/i);
          const lineNum = match ? parseInt(match[1], 10) : i + 1;
          return {
            severity: monaco.MarkerSeverity.Error,
            message: line,
            startLineNumber: lineNum,
            endLineNumber: lineNum,
            startColumn: 1,
            endColumn: 100,
          };
        });
        monaco.editor.setModelMarkers(model, 'owner', markers);
      }
    } catch (err) {
      setErrors(['Failed to check syntax: ' + err.message]);
    }
    setLoadingSyntax(false);
  };

  const handleAcceptClean = () => {
    const cleanCode = removeComments(suggestion);
    setCode(cleanCode);
    setAccepted(true);
  };

  const handleAcceptAll = () => {
    setCode(suggestion);
    setAccepted(true);
  };

  const handleReject = () => {
    setAccepted(false);
  };

  const handleEditorDidMount = (editor) => {
    editorRef.current = editor;
    editor.addAction({
      id: 'run-code',
      label: 'Run Code',
      contextMenuGroupId: 'navigation',
      contextMenuOrder: 0,
      run: () => {
        alert('Run feature not implemented. You can add runtime support later.');
      },
    });
    editor.addAction({
      id: 'format-code',
      label: 'Format Document',
      contextMenuGroupId: 'navigation',
      contextMenuOrder: 1,
      run: handleFormat,
    });
  };

  const toggleTheme = () => {
    setTheme((prev) => (prev === 'vs-dark' ? 'light' : 'vs-dark'));
  };

  return (
    <div className={`app-container ${theme}`}>
      <button onClick={toggleTheme} className="theme-toggle">
        {theme === 'vs-dark' ? '☀️ Light Mode' : '🌙 Dark Mode'}
      </button>

      <h1>ML Code Analyzer</h1>

      <div className="top-bar">
        <input type="file" accept=".py,.java,.c,.cpp,.txt" onChange={handleFileUpload} />
      </div>

      <p><strong>Detected Language:</strong> {language || 'N/A'}</p>

      <div className="editor-wrapper">
        <Editor
          height="40vh"
          language={language || 'plaintext'}
          value={code}
          onChange={handleEditorChange}
          theme={theme}
          onMount={handleEditorDidMount}
          options={{
            fontSize: 14,
            wordWrap: 'on',
            minimap: { enabled: false },
            formatOnPaste: true,
            formatOnType: true,
            scrollBeyondLastLine: false,
            tabSize: 2,
          }}
        />
      </div>

      <div style={{ marginTop: '1rem' }}>
        <button
          onClick={handleMLSuggestion}
          disabled={loadingSuggestion || loadingSyntax}
        >
          {loadingSuggestion ? 'Analyzing...' : 'Get AI Suggestion'}
        </button>
        <button
          onClick={handleSyntaxCheck}
          disabled={loadingSyntax || loadingSuggestion}
        >
          {loadingSyntax ? 'Checking Syntax...' : 'Check Syntax'}
        </button>
      </div>

      {errors.length > 0 && (
        <div className={`output-panel ${theme}`}>
          <h3>Syntax Errors:</h3>
          <ul>
            {errors.map((e, i) => (
              <li key={i}>{e}</li>
            ))}
          </ul>
        </div>
      )}

      {suggestion && (
        <div className={`output-panel ${theme}`}>
          <h3>AI Suggestion (After):</h3>
          <pre>{suggestion}</pre>
          <h4>Original Code (Before):</h4>
          <pre>{code}</pre>
          <button onClick={handleAcceptClean}>✅ Accept Clean</button>
          <button onClick={handleAcceptAll}>📝 Accept All</button>
          <button onClick={handleReject}>Reject</button>
          {accepted !== null && <p>{accepted ? 'Accepted ✅' : 'Rejected ❌'}</p>}
          {score !== null && <p>Similarity Score: {score.toFixed(2)}%</p>}
        </div>
      )}
    </div>
  );
}

export default App;
