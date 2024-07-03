document.addEventListener('DOMContentLoaded', function() {
  const board = document.getElementById('game-board');
  const apiUrl = 'http://localhost:3000'; // Atualize com a URL da sua API
  let gameId;
  let playerToken;
  let selectedPiece = null;
  let possibleMoves = [];

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
    document.querySelector(`.piece[data-id="${piece.id}"]`).classList.add('selected');
    fetchPossibleMoves(piece);
  }

  function deselectPiece() {
    if (selectedPiece) {
      document.querySelector(`.piece[data-id="${selectedPiece.id}"]`).classList.remove('selected');
      selectedPiece = null;
      possibleMoves = [];
      updateBoardHighlight();
    }
  }

  function fetchPossibleMoves(piece) {
    fetch(`${apiUrl}/games/${gameId}/moves/${piece.id}`, {
      method: 'GET',
      headers: { 'Authorization': playerToken }
    })
    .then(response => response.json())
    .then(data => {
      possibleMoves = data.moves;
      updateBoardHighlight();
    });
  }

  // function movePiece(piece, row, col) {
  //   fetch(`${apiUrl}/games/${gameId}/move`, {
  //     method: 'POST',
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': playerToken }
  //     ,
  //     body: JSON.stringify({
  //       piece_id: piece.id,
  //       destination: { row: row, col: col }
  //     })
  //   })
  //   .then(response => response.json())
  //   .then(data => {
  //     if (data.success) {
  //       updatePiecePosition(piece.id, row, col);
  //       deselectPiece();
  //     } else {
  //       alert(data.error);
  //     }
  //   });
  // }

  function movePiece(piece, row, col) {
    fetch(`${apiUrl}/games/${gameId}/move`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': playerToken
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
        deselectPiece();
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
    pieceElement.style.top = `${row * 50}px`;
    pieceElement.style.left = `${col * 50}px`;
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
      playerToken = data.player1_token;
      document.getElementById('game-id').querySelector('span').textContent = gameId;
      document.getElementById('player2-token').querySelector('span').textContent = playerToken;
      loadGame();
    })
    .catch(error => {
      console.error('Error creating game:', error);
    });
  }

  function joinGame(token) {
    fetch(`${apiUrl}/games/${gameId}/join`, {
      method: 'POST',
      headers: { 'Authorization': token }
    })
    .then(response => response.json())
    .then(data => {
      playerToken = data.player2_token;
      document.getElementById('player2-token').querySelector('span').textContent = playerToken;
      loadGame();
    })
    .catch(error => {
      console.error('Error joining game:', error);
    });
  }

  function loadGame() {
    fetch(`${apiUrl}/games/${gameId}/pieces`, {
      method: 'GET',
      headers: { 'Authorization': playerToken }
    })
    .then(response => response.json())
    .then(pieces => {
      initializeBoard();
      loadPieces(pieces);
    })
    .catch(error => {
      console.error('Error loading game:', error);
    });
  }

  document.getElementById('create-game').addEventListener('click', createGame);

  document.getElementById('join-game').addEventListener('click', () => {
    const token = prompt('Enter game token:');
    joinGame(token);
  });

  initializeBoard();
});
