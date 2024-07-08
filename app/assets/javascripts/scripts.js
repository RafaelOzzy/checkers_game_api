document.addEventListener('DOMContentLoaded', function() {
  const board = document.getElementById('game-board');
  const apiUrl = 'http://localhost:3000'; // Atualize com a URL da sua API
  let gameId;
  let gameToken;
  let player;
  let selectedPiece = null;
  let possibleMoves = [];
  let captureMovesAvailable = false;
  let continueCapture = false;
  let gameFinished = false;

  function initializeBoard() {
    board.innerHTML = '';
    for (let row = 0; row < 8; row++) {
      for (let col = 0; col < 8; col++) {
        const square = document.createElement('div');
        square.className = 'square';
        square.classList.add((row + col) % 2 === 0 ? 'light' : 'dark');
        square.dataset.row = row;
        square.dataset.col = col;
        square.addEventListener('click', () => handleSquareClick(row, col));
        board.appendChild(square);
      }
    }
  }

  function loadPieces(pieces) {
    pieces.forEach(piece => {
      const pieceElement = document.createElement('div');
      pieceElement.className = `piece player${piece.player}`;
      if (piece.king) {
        pieceElement.classList.add('king');
      }
      pieceElement.dataset.id = piece.id;
      pieceElement.style.top = `${piece.row * 50}px`;
      pieceElement.style.left = `${piece.col * 50}px`;
      pieceElement.addEventListener('click', (e) => {
        e.stopPropagation();
        handlePieceClick(piece);
      });
      board.appendChild(pieceElement);
    });
  }

  function handlePieceClick(piece) {
    if (piece.player !== parseInt(player)) return; // Only allow the player to select their own pieces

    if (selectedPiece && selectedPiece.id === piece.id) {
      deselectPiece();
    } else {
      selectPiece(piece);
    }
  }

  function handleSquareClick(row, col) {
    if (selectedPiece && possibleMoves.some(move => move.row === row && move.col === col)) {
      movePiece(selectedPiece, row, col);
    }
  }

  function selectPiece(piece) {
    deselectPiece();
    selectedPiece = piece;
    const selectedElement = document.querySelector(`.piece[data-id="${piece.id}"]`);
    if (selectedElement) {
      selectedElement.classList.add('selected');
    }
    fetchPossibleMoves(piece);
  }

  function deselectPiece() {
    if (selectedPiece) {
      const selectedElement = document.querySelector(`.piece[data-id="${selectedPiece.id}"]`);
      if (selectedElement) {
        selectedElement.classList.remove('selected');
      }
      selectedPiece = null;
      possibleMoves = [];
      updateBoardHighlight();
    }
  }

  function fetchPossibleMoves(piece) {
    fetch(`${apiUrl}/games/${gameId}/moves/${piece.id}`, {
      method: 'GET',
      headers: { 'Authorization': gameToken }
    })
    .then(response => response.json())
    .then(data => {
      possibleMoves = data.moves;
      captureMovesAvailable = possibleMoves.some(move => Math.abs(piece.row - move.row) == 2);
      updateBoardHighlight();
    })
    .catch(error => {
      console.error('Error fetching possible moves:', error);
    });
  }

  function movePiece(piece, row, col) {
    fetch(`${apiUrl}/games/${gameId}/move`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': gameToken,
        'Player': player
      },
      body: JSON.stringify({
        piece_id: piece.id,
        destination: { row: row, col: col }
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        updatePiecePosition(piece.id, row, col);
        if (data.continue_capture) {
          continueCapture = true;
          selectPiece(piece);
        } else {
          continueCapture = false;
          deselectPiece();
          fetchGameStatus();
          fetchGamePieces();
        }
      } else {
        alert(data.error);
      }
    })
    .catch(error => {
      console.error('Error moving piece:', error);
    });
  }

  function updatePiecePosition(id, row, col) {
    const pieceElement = document.querySelector(`.piece[data-id="${id}"]`);
    if (pieceElement) {
      pieceElement.style.top = `${row * 50}px`;
      pieceElement.style.left = `${col * 50}px`;
    }
  }

  function updateBoardHighlight() {
    document.querySelectorAll('.square').forEach(square => {
      square.classList.remove('highlight');
    });
    possibleMoves.forEach(move => {
      const square = document.querySelector(`.square[data-row="${move.row}"][data-col="${move.col}"]`);
      if (square) {
        square.classList.add('highlight');
      }
    });
  }

  function createGame() {
    fetch(`${apiUrl}/games`, {
      method: 'POST'
    })
    .then(response => response.json())
    .then(data => {
      gameId = data.game_id;
      gameToken = data.game_token;
      player = '1'; // The creator of the game is always player 1
      document.getElementById('game-id').querySelector('span').textContent = gameId;
      document.getElementById('game-token').querySelector('span').textContent = gameToken;
      loadGame();
    })
    .catch(error => {
      console.error('Error creating game:', error);
    });
  }

  function joinGame() {
    const gameIdInput = document.getElementById('game-id-input').value;
    const gameTokenInput = document.getElementById('game-token-input').value;
    if (!gameIdInput || !gameTokenInput) {
      alert('Please enter a valid game ID and game token');
      return;
    }
    gameId = gameIdInput;
    gameToken = gameTokenInput;
    player = '2'; // The joiner of the game is always player 2
    fetch(`${apiUrl}/games/${gameId}/join`, {
      method: 'POST',
      headers: { 'Authorization': gameToken }
    })
    .then(response => response.json())
    .then(data => {
      document.getElementById('game-id').querySelector('span').textContent = gameId;
      document.getElementById('game-token').querySelector('span').textContent = gameToken;
      loadGame();
    })
    .catch(error => {
      console.error('Error joining game:', error);
    });
  }

  function loadGame() {
    fetch(`${apiUrl}/games/${gameId}/pieces`, {
      method: 'GET',
      headers: { 'Authorization': gameToken }
    })
    .then(response => response.json())
    .then(pieces => {
      initializeBoard();
      loadPieces(pieces);
      fetchGameStatus();
    })
    .catch(error => {
      console.error('Error loading game:', error);
    });
  }

  function fetchGameStatus() {
    fetch(`${apiUrl}/games/${gameId}/status`, {
      method: 'GET',
      headers: { 'Authorization': gameToken }
    })
    .then(response => response.json())
    .then(data => {
      document.getElementById('game-status').querySelector('span').textContent = data.status;
      if (data.status === 'player_1_won' || data.status === 'player_2_won') {
        gameFinished = true;
      }
    })
    .catch(error => {
      console.error('Error fetching game status:', error);
    });
  }

  function fetchGamePieces() {
    fetch(`${apiUrl}/games/${gameId}/pieces`, {
      method: 'GET',
      headers: { 'Authorization': gameToken }
    })
    .then(response => response.json())
    .then(pieces => {
      initializeBoard();
      loadPieces(pieces);
    })
    .catch(error => {
      console.error('Error fetching game pieces:', error);
    });
  }

  document.getElementById('create-game').addEventListener('click', createGame);
  document.getElementById('join-game').addEventListener('click', joinGame);

  initializeBoard();

  setInterval(() => {
    if (gameId && gameToken && !continueCapture && !gameFinished) {
      fetchGameStatus();
      fetchGamePieces();
    }
  }, 5000); // Atualiza o estado do jogo a cada 5 segundos
});
